module: packetizer
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define macro unsupplied-or
  { unsupplied-or(?:expression) }
 =>
  { type-union(singleton($unsupplied), ?expression) }
end; 

define macro protocol-module-definer
  { protocol-module-definer (?:name; ?super:name; ?fields:*) }
 => { define module ?name
        use dylan;
        use packetizer;
        //?super;
        create "<" ## ?name ## ">";
        ?fields
      end; }

  fields:
    { } => { }
    { field ?filter:name ?rest:* ; ... } => { ?filter ... }
    { repeated field ?filter:name ?rest:* ; ... } => { ?filter ... }
    { variably-typed-field ?filter:name ?rest:* ; ... } => { ?filter ... }


  super:
    { container-frame } => { }
    { header-frame } => { }
    { ?:name } => { use ?name; }

  filter:
    { source-address } => { }
    { destination-address } => { }
    { payload } => { }
    { ?:name } => { create ?name, ?name ## "-setter"; }

end;

define inline function filter-enums
    (key/value-pairs :: <collection>, fields :: <collection>)
 => (args :: <collection>)
  let args = copy-sequence(key/value-pairs);
  for (ele in fields)
    if (instance?(ele, <enum-field>))
      let pos
        = block(ret)
            for (i :: <integer> from 0 below key/value-pairs.size by 2)
              if (key/value-pairs[i] == ele.field-name)
                ret(i + 1);
              end;
            end;
          end;
      if (pos)
        let key = key/value-pairs[pos];
        if (instance?(key, <symbol>))
          //format-out("changed %= from %= to %=\n", ele.field-name, key, enum-field-symbol-to-int(ele, key));
          args[pos] := enum-field-symbol-to-int(ele, key);
        end;
      end;
    end;
  end;
  //format-out("returning from filter-enum1\n");
  args;
end;


define macro real-class-definer
  { real-class-definer(?attrs:*; ?:name; ?superclasses:*; ?fields-aux:*) }
 => { define abstract class ?name (?superclasses)
      end;
      define inline method frame-name (frame :: subclass(?name)) => (res :: <string>)
        ?"name"
      end;
      // XXX: unify clients
      define inline method fields (frame :: ?name) => (res :: <simple-vector>)
          "$" ## ?name ## "-fields"
      end;
      define inline method fields (frame-type :: subclass(?name)) => (res :: <simple-vector>)
          "$" ## ?name ## "-fields"
      end;
      define method fields-initializer
       (frame :: subclass(?name), #next next-method) => (frame-fields :: <simple-vector>)
        let res = concatenate(next-method(), vector(?fields-aux));
        for (ele in res, i from 0)
          ele.index := i;
        end;
        res;
      end;
      define constant "$" ## ?name ## "-fields" = fields-initializer(?name);
      begin
        compute-static-offset("$" ## ?name ## "-fields");
        if (element($protocols, ?#"name", default: #f))
          error("Protocol with same name already exists");
        else
          $protocols[?#"name"] := ?name;
        end;
      end;
      define constant "$" ## ?name ## "-layer-bonding"
        = begin
            let res = choose(rcurry(instance?, <layering-field>), "$" ## ?name ## "-fields");
            if (res.size = 1)
              res[0].getter;
            end;
          end;
      define inline method layer-magic (frame :: ?name) => (res)
         if ("$" ## ?name ## "-layer-bonding")
           "$" ## ?name ## "-layer-bonding"(frame);
         end;
      end;
      define inline method field-size (frame :: subclass(?name)) => (res :: <number>)
        if (find-method(container-frame-size, list(?name)))
          $unknown-at-compile-time;
        elseif (?#"attrs" == #"abstract")
          $unknown-at-compile-time;
        else
          static-end(last("$" ## ?name ## "-fields"));
        end;
      end;
      define method make (class == ?name,
                          #rest rest, #key, #all-keys) => (res :: ?name)
        let args = filter-enums(rest, "$" ## ?name ## "-fields");
        let frame = apply(make, decoded-class(?name), args);
        for (field in fields(frame))
          if (field.getter(frame) = $unsupplied)
            field.setter(field.init-value, frame);
          end;
        end;
        frame;
      end;
    }

  fields-aux:
   { } => { }
   { variably-typed-field ?:name, ?args:*; ... }
     => { make(<variably-typed-field>,
               name: ?#"name",
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }
   { variably-typed-field ?:name = ?init:expression , ?args:*; ... }
     => { make(<variably-typed-field>,
               name: ?#"name",
               init-value: ?init,
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }
   { ?attributes:* field ?:name \:: ?field-type:name; ... }
     => { make(?attributes,
               name: ?#"name",
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter"), ... }
   { ?attributes:* field ?:name \:: ?field-type:name, ?args:*; ... }
     => { make(?attributes,
               name: ?#"name",
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }
   { ?attributes:* field ?:name \:: ?field-type:name = ?init:expression ; ... }
     => { make(?attributes,
               name: ?#"name",
               init-value: ?init,
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter"), ... }
   { ?attributes:* field ?:name \:: ?field-type:name = ?init:expression , ?args:*; ... }
     => { make(?attributes,
               name: ?#"name",
               init-value: ?init,
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }

  attributes:
    { } => { <single-field> }
    { layering } => { <layering-field> }
    { repeated } => { <repeated-field> }
    { enum } => { <enum-field> }

  args: //FIXME: better types, not <frame>!
    { } => { }
    { start: ?start:expression, ... }
      => { dynamic-start: method(?=frame :: <frame>) ?start end, ... }
    { end: ?end:expression, ... }
      => { dynamic-end: method(?=frame :: <frame>) ?end end, ... }
    { length: ?length:expression, ... }
      => { dynamic-length: method(?=frame :: <frame>) ?length end, ... }
    { count: ?count:expression, ... }
      => { count: method(?=frame :: <frame>) ?count end, ... }
    { type-function: ?type:expression, ... }
      => { type-function: method(?=frame :: <frame>) ?type end, ... }
    { reached-end?: ?reached:expression, ... }
      => { reached-end?: method(?=frame) ?reached end, ... }
    { fixup: ?fixup:expression, ... }
      => { fixup: method(?=frame :: <frame>) ?fixup end, ... }
    { static-start: ?start:expression, ... }
      => { static-start: ?start, ... }
    { static-length: ?length:expression, ... }
      => { static-length: ?length, ... }
    { static-end: ?end:expression, ... }
      => { static-end: ?end, ... }
    { mappings: { ?mappings }, ... }
      => { mappings: #( ?mappings ), ... }

  mappings:
    { } => { }
    { ?key:expression <=> ?value:expression, ... }
      => { ?key, ?value, ... }
end;


define macro decoded-class-definer
    { decoded-class-definer(?:name; ?superclasses:*; ?fields:*) }
      => { define class ?name (?superclasses) ?fields end }

    fields:
    { } => { }
    { ?field:*; ... } => { ?field ; ... }
    
    field:
    { variably-typed-field ?:name, ?rest:* }
    => { slot ?name :: unsupplied-or(<frame>) = $unsupplied,
      init-keyword: ?#"name" }
    { repeated field ?:name ?rest:* }
      => { slot ?name :: unsupplied-or(<collection>) = $unsupplied,
      init-keyword: ?#"name" }
    { enum field ?:name \:: ?field-type:name ?rest:* }
    => { slot "%" ## ?name :: unsupplied-or(high-level-type(?field-type)) = $unsupplied,
         init-keyword: ?#"name" }
    { ?attrs:* field ?:name \:: ?field-type:name ?rest:* }
    => { slot ?name :: unsupplied-or(high-level-type(?field-type)) = $unsupplied,
      init-keyword: ?#"name" }
end;

define macro gen-classes
  { gen-classes(?:name; ?superframe:name) }
 => { define inline method unparsed-class
       (type :: subclass("<" ## ?name ## ">")) => (class == "<unparsed-" ## ?name ## ">");
        "<unparsed-" ## ?name ## ">"
      end;

      define inline method decoded-class
       (type :: subclass("<" ## ?name ## ">")) => (class == "<decoded-" ## ?name ## ">");
        "<decoded-" ## ?name ## ">"
      end;

      define class "<unparsed-" ## ?name ## ">" ("<" ## ?name ## ">", "<unparsed-" ## ?superframe ## ">")
        //sadly, inherited slots can't specify a type (and generate a warning if you try)
        inherited slot cache /* :: "<" ## ?name ## ">" */ = make("<decoded-" ## ?name ## ">"),
          init-keyword: cache:;
      end; }
end;

define macro unparsed-frame-field-generator
  { unparsed-frame-field-generator(?:name,
                                   ?frame-type:name,
                                   ?field-index:expression) }
 => { define inline method ?name (mframe :: ?frame-type) => (res)
         if (mframe.cache.?name ~== $unsupplied)
           mframe.cache.?name
         else
          let frame-field = get-frame-field(?field-index, mframe);
          let (value, parsed-end) = parse-frame-field(frame-field);
          mframe.cache.?name := value;
          if (parsed-end)
            frame-field.%end-offset := parsed-end;
            frame-field.%length := parsed-end - frame-field.start-offset;
          end;
          mframe.cache.?name
        end;
      end;
      define inline method ?name ## "-setter" (value, mframe :: ?frame-type) => (res)
        mframe.cache.?name := value;
        let frame-field = get-frame-field(?field-index, mframe);
        // blatantly ignores changed length, FIXME!
        assemble-field-into(frame-field.field, mframe, subsequence(mframe.packet, start: start-offset(frame-field)));
        value;
      end;
 }
end;

define inline function enum-field-symbol-to-int
    (field :: <enum-field>, key :: <symbol>) => (res :: <integer>)
  block(ret)
    for (i from 1 below field.mappings.size by 2)
      if (field.mappings[i] == key)
        ret(field.mappings[i - 1])
      end;
    end;
    error("unknown symbol for enum field");
  end;
end;

define macro enum-frame-field-generator
  { enum-frame-field-generator(?:name,
                               "<unparsed-" ## ?frame-type:name,
                               ?field-index:expression) }
 => { define inline method ?name (mframe :: "<decoded-" ## ?frame-type) => (res)
        let field = fields(mframe)[?field-index];
        let val = "%" ## ?name (mframe);
        block(ret)
          for (i from 0 below field.mappings.size by 2)
            if (field.mappings[i] == val)
              ret(field.mappings[i + 1])
            end;
          end;
          val
        end;
      end;
      define inline method ?name ## "-setter"
          (value :: <symbol>, mframe :: "<decoded-" ## ?frame-type) => (res)
        let field = fields(mframe)[?field-index];
        let val :: <integer> = enum-field-symbol-to-int(field, value);
        "%" ## ?name ## "-setter"(val , mframe);
      end;
      define inline method ?name ## "-setter"
          (value :: false-or(<integer>),
           mframe :: "<decoded-" ## ?frame-type) => (res)
        "%" ## ?name ## "-setter"(value, mframe);
      end;
      define inline method ?name ## "-setter"
          (value :: <symbol>, mframe :: "<unparsed-" ## ?frame-type) => (res)
        let field = fields(mframe)[?field-index];
        let val :: <integer> = enum-field-symbol-to-int(field, value);
        ?name ## "-setter" (val, mframe)
      end;
 }
end;


define method parse-frame-field
   (frame-field :: <frame-field>)
 => (res, length);
 let full-frame-size = frame-field.frame.packet.size * 8;
 let start = frame-field.start-offset;
 let my-length = compute-field-length(frame-field);
 let end-of-field
   = if (my-length)
       start + my-length
     elseif (compute-field-end(frame-field))
       compute-field-end(frame-field);
     elseif (frame-field.field.index = field-count(frame-field.frame.object-class) - 1)
       //last field, just return the end...
       full-frame-size;
     else
       let successor-field = frame-field.frame.fields[frame-field.field.index + 1];
       if (successor-field.dynamic-start)
         //should we generate a half-done frame-field here?
         //somehow, we should cache the result...
         successor-field.dynamic-start(frame-field.frame)
       else
         //maybe we should try to find length of remaining fixed-size fields?
         //format-out("Not able to find end of field %s\n", frame-field.field.field-name);
         full-frame-size;
       end;
     end;

  if (end-of-field > full-frame-size)
    //format-out("Wanted to read beyond frame, field %s start %d end %d frame-size %d\n",
    //           frame-field.field.field-name, start, end-of-field, full-frame-size);
    end-of-field := full-frame-size;
  end;
  let (value, length)
    = parse-frame-field-aux(frame-field.field,
                            frame-field.frame,
                            subsequence(frame-field.frame.packet,
                                        start: start,
                                        end: end-of-field));
  if (length)
    let real-end = length + start;
    unless (real-end = end-of-field)
      if (real-end < end-of-field)
        //format-out("estimated end in %s at %d (%d bytes), but parser was done after %d (%d bytes)\n",
        //           frame-field.field.field-name, end-of-field, byte-offset(end-of-field), real-end, byte-offset(real-end));
        //padding? only if end-of-field ~= end-of-frame!?
        end-of-field := real-end;
      else
        error("This shouldn't happen... in %s, start %d end %d (%d bits), used %d\n",
              frame-field.field.field-name, start, end-of-field, end-of-field - start, length);
      end;
    end;
  else
    end-of-field := #f
  end;
  values(value, end-of-field);
end;

define method parse-frame-field-aux
 (field :: <single-field>,
  frame :: <unparsed-container-frame>,
  packet :: <byte-sequence>)
 parse-frame(field.type, packet, parent: frame);
end;
define method parse-frame-field-aux
  (field :: <variably-typed-field>,
   frame :: <unparsed-container-frame>,
   packet :: <byte-sequence>)
  let type = field.type-function(frame);
  parse-frame(type, packet, parent: frame);
end;

//XXX: refactor here. parse more lazy; use <frame-field> infrastructure
define method parse-frame-field-aux
  (field :: <self-delimited-repeated-field>,
   frame :: <unparsed-container-frame>,
   packet :: <byte-sequence>)
  let frames = make(<stretchy-vector>);
  let ff = get-frame-field(field.index, frame);
  let frame-fields = ff.frame-field-list;
  let start :: <integer> = 0;
  if (packet.size > 0)
    let (value, offset)
      = parse-frame(field.type,
                    subsequence(packet, start: start),
                    parent: frame);
    unless (offset)
      offset := end-offset(get-frame-field(field-count(value.object-class) - 1, value));
    end;
    frames := add!(frames, value);
    frame-fields := add!(frame-fields,
                         make(<rep-frame-field>,
                              start: start,
                              end: start + offset,
                              length: offset,
                              frame: value,
                              parent: ff));
    start := start + offset;
    while ((~ field.reached-end?(frames.last)) & (byte-offset(start) < packet.size))
      let (value, offset)
        = parse-frame(field.type,
                      subsequence(packet, start: start),
                      parent: frame);
      unless (offset)
        offset := end-offset(get-frame-field(field-count(value.object-class) - 1, value));
      end;
      frames := add!(frames, value);
      frame-fields := add!(frame-fields,
                           make(<rep-frame-field>,
                                start: start,
                                end: start + offset,
                                length: offset,
                                frame: value,
                                parent: ff));
      start :=  start + offset;
    end;
  end;
  values(frames, start);
end;
define method parse-frame-field-aux
  (field :: <count-repeated-field>,
   frame :: <unparsed-container-frame>,
   packet :: <byte-sequence>)
  let frames = make(<stretchy-vector>);
  let ff = get-frame-field(field.index, frame);
  let frame-fields = ff.frame-field-list;
  let start :: <integer> = 0;
  if (packet.size > 0)
    for (i from 0 below field.count(frame))
      let (value, offset)
        = parse-frame(field.type,
                      subsequence(packet, start: start),
                      parent: frame);
      unless (offset)
        offset := end-offset(get-frame-field(field-count(value.object-class) - 1, value));
      end;
      frames := add!(frames, value);
      frame-fields := add!(frame-fields,
                           make(<rep-frame-field>,
                                start: start,
                                end: start + offset,
                                length: offset,
                                frame: value,
                                parent: ff));
      start := start + offset;
    end;
  end;
  values(frames, start);
end;

define method parse-frame (frame-type :: subclass(<variably-typed-container-frame>),
                           packet :: <byte-sequence>,
                           #key parent :: false-or(<container-frame>),
                           default)
  let superprotocol-frame = next-method();
  let real-type = lookup-layer(frame-type, layer-magic(superprotocol-frame));
  if (real-type & (real-type ~== frame-type))
    parse-frame(real-type, packet, parent: parent);
  else
    if (default)
      parse-frame(default, packet, parent: parent);
    else
      superprotocol-frame
    end;
  end;
end;

define method parse-frame (frame-type :: subclass(<container-frame>),
                           byte-packet :: <byte-sequence>,
                           #key parent :: false-or(<container-frame>))
  let frame = make(unparsed-class(frame-type),
                   packet: byte-packet,
                   parent: parent);
  let length = field-size(frame-type);
  if (length = $unknown-at-compile-time)
    block (ret)
      let fr-length = container-frame-size(frame);
      if (fr-length)
        frame.packet := subsequence(frame.packet, length: fr-length);
        ret(apply(values, frame, fr-length));
      end;
    exception (e :: <error>)
      frame;
    end;
  else
    values(frame, length)
  end;
end;

define macro frame-field-generator
    { frame-field-generator(?type:name; ?count:expression; enum field ?field-name:name ?foo:*  ; ?rest:*) }
    => { enum-frame-field-generator(?field-name, ?type, ?count);
         unparsed-frame-field-generator(?field-name, ?type, ?count);
         frame-field-generator(?type; ?count + 1; ?rest) }
    { frame-field-generator(?type:name; ?count:expression; repeated field ?field-name:name ?foo:*  ; ?rest:*) }
    => { unparsed-frame-field-generator(?field-name, ?type, ?count);
         frame-field-generator(?type; ?count + 1; ?rest) }
    { frame-field-generator(?type:name; ?count:expression; layering field ?field-name:name ?foo:*  ; ?rest:*) }
    => { unparsed-frame-field-generator(?field-name, ?type, ?count);
         frame-field-generator(?type; ?count + 1; ?rest) }
    { frame-field-generator(?type:name; ?count:expression; field ?field-name:name ?foo:*  ; ?rest:*) }
    => { unparsed-frame-field-generator(?field-name, ?type, ?count);
         frame-field-generator(?type; ?count + 1; ?rest) }
    { frame-field-generator(?type:name; ?count:expression; variably-typed-field ?field-name:name ?foo:* ; ?rest:*) }
    => { unparsed-frame-field-generator(?field-name, ?type, ?count);
         frame-field-generator(?type; ?count + 1; ?rest) }
    { frame-field-generator(?:name; ?count:expression) }
    => { define inline method field-count (type :: subclass(?name)) => (res :: <integer>) ?count end; }
end;

define macro summary-generator
    { summary-generator(?type:name; ?summary-string:expression, ?summary-getters:*) }
    => { define method summary (frame :: ?type) => (result :: <string>);
           apply(format-to-string,
                 ?summary-string,
                 map(rcurry(apply, list(frame)), list(?summary-getters)));
         end; }
end;

define macro container-frame-constructor
  { container-frame-constructor(?:name) }
 =>
  { define inline method ?name (#rest args)
      apply(make, "<" ## ?name ## ">", args)
    end
  }
end;

define macro protocol-definer
    { define ?attrs:* protocol ?:name (?superprotocol:name)
        summary ?summary:* ;
        ?fields:*
      end } =>
      { summary-generator("<" ## ?name ## ">"; ?summary);
        define ?attrs protocol ?name (?superprotocol) ?fields end; }


    { define ?attrs:* protocol ?:name (container-frame) end } =>
      { //protocol-module-definer(?name; container-frame; );
        define abstract class "<" ## ?name ## ">" (<container-frame>) end;
        define abstract class "<decoded-" ## ?name ## ">"
         ("<" ## ?name ## ">", <decoded-container-frame>)
        end;
        gen-classes(?name; container-frame); }

    { define ?attrs:* protocol ?:name (?superprotocol:name)
        over ?super:name ?magic:expression;
        ?fields:*
      end } =>
      { 
        define ?attrs protocol ?name (?superprotocol) ?fields end;
        define method lookup-layer (frame :: subclass(?super), value == ?magic) => (class :: <class>) "<" ## ?name ## ">" end;
        define method reverse-lookup-layer (frame :: subclass(?super), payload :: "<" ## ?name ## ">") => (value :: <integer>) ?magic end;
      }
 
    { define ?attrs:* protocol ?:name (?superprotocol:name)
        length ?container-frame-length:expression;
        ?fields:*
      end } =>
      { 
        define ?attrs protocol ?name (?superprotocol) ?fields end;
        define inline method container-frame-size (?=frame :: "<" ## ?name ## ">") => (res :: <integer>)
          ?container-frame-length
        end;
      }


    { define ?attrs:* protocol ?:name (?superprotocol:name)
        ?fields:*
      end } =>
      { //protocol-module-definer(?name; ?superprotocol; ?fields);
        real-class-definer(?attrs; "<" ## ?name ## ">"; "<" ## ?superprotocol ## ">"; ?fields);
        decoded-class-definer("<decoded-" ## ?name ## ">";
                              "<" ## ?name ## ">", "<decoded-" ## ?superprotocol ## ">";
                              ?fields);
        gen-classes(?name; ?superprotocol);
        frame-field-generator("<unparsed-" ## ?name ## ">";
                              field-count("<unparsed-" ## ?superprotocol ## ">");
                              ?fields);
        container-frame-constructor(?name);
      }
end;

