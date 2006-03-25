module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define macro real-class-definer
  { real-class-definer(?:name; ?superclasses:*; ?fields:*) }
 => { define abstract class ?name (?superclasses)
      end;
      define inline method frame-fields (frame :: subclass(?name), #next next-method) => (fields :: <list>)
        concatenate(next-method(), list(?fields));
      end;
      define inline method name (frame :: ?name)
        ?"name"
      end;
      define method make (class == ?name, #rest rest, #key, #all-keys) => (res :: ?name)
        let frame = apply(make, cache-class(?name), rest);
        for (field in frame-fields(?name))
          if (field.getter(frame) = #f)
            field.setter(field.init-value, frame);
          end;
        end;
        frame;
      end;
 }

  fields:
   { } => { }
   { field ?:name \:: ?field-type:name; ... }
     => { make(<single-field>,
               name: ?#"name",
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter"), ... }
   { field ?:name \:: ?field-type:name, ?args:*; ... }
     => { make(<single-field>,
               name: ?#"name",
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }
   { variably-typed-field ?:name, ?args:*; ... }
     => { make(<variably-typed-field>,
               name: ?#"name",
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }
   { repeated field ?:name \:: ?field-type:name, ?args:*; ... }
     => { make(<repeated-field>,
               name: ?#"name",
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }
   { field ?:name \:: ?field-type:name = ?init:expression ; ... }
     => { make(<single-field>,
               name: ?#"name",
               init: ?init,
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter"), ... }
   { field ?:name \:: ?field-type:name = ?init:expression , ?args:*; ... }
     => { make(<single-field>,
               name: ?#"name",
               init: ?init,
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }
   { variably-typed-field ?:name = ?init:expression , ?args:*; ... }
     => { make(<variably-typed-field>,
               name: ?#"name",
               init: ?init,
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }
   { repeated field ?:name \:: ?field-type:name = ?init:expression, ?args:*; ... }
     => { make(<repeated-field>,
               name: ?#"name",
               init: ?init,
               type: ?field-type,
               getter: ?name,
               setter: ?name ## "-setter",
               ?args), ... }

  args: //FIXME: better types, not <frame>!
    { } => { }
    { start: ?start:expression, ... }
      => { start: method(?=frame :: <frame>) ?start end, ... }
    { end: ?end:expression, ... }
      => { end: method(?=frame :: <frame>) ?end end, ... }
    { length: ?length:expression, ... }
      => { length: method(?=frame :: <frame>) ?length end, ... }
    { count: ?count:expression, ... }
      => { count: method(?=frame :: <frame>) ?count end, ... }
    { type-function: ?type:expression, ... }
      => { type-function: method(?=frame :: <frame>) ?type end, ... }
    { reached-end?: ?reached:expression, ... }
      => { reached-end?: ?reached, ... }
    { fixup: ?fixup:expression, ... }
      => { fixup: method(?=frame :: <frame>) ?fixup end, ... }
end;

define macro cache-class-definer
    { cache-class-definer(?:name; ?superclasses:*; ?fields:*) } 
    => { define class ?name (?superclasses) ?fields end }
    
    fields:
    { } => { }
    { ?field:*; ... } => { ?field ; ... }
    
    field:
    { field ?:name \:: ?field-type:name ?rest:* }
      => { slot ?name :: false-or(high-level-type(?field-type)) = #f, init-keyword: ?#"name" }
    { variably-typed-field ?:name, ?rest:* }
      => { slot ?name :: false-or(<frame>) = #f, init-keyword: ?#"name" }
    { repeated field ?:name ?rest:* }
      => { slot ?name :: false-or(<stretchy-vector>) = #f, init-keyword: ?#"name" }
    
end;

define macro decoded-class-definer
    { decoded-class-definer(?:name; ?superclasses:*; ?fields:*) }
      => { define class ?name (?superclasses) ?fields end }

    fields:
    { } => { }
    { ?field:*; ... } => { ?field ; ... }
    
    field:
    { field ?:name \:: ?field-type:name ?rest:* }
    => { slot ?name :: high-level-type(?field-type),
      required-init-keyword: ?#"name" }
    { variably-typed-field ?:name, ?rest:* }
    => { slot ?name :: <frame>,
      required-init-keyword: ?#"name" }
    { repeated field ?:name ?rest:* }
      => { slot ?name :: <stretchy-vector>,
      required-init-keyword: ?#"name" }
end;

define macro gen-classes
  { gen-classes(?:name; ?superframe:name) }
 => { define inline method cache-class
       (type :: subclass("<" ## ?name ## ">")) => (class == "<" ## ?name ## "-cache>");
        "<" ## ?name ## "-cache>"
      end;

      define inline method unparsed-class
       (type :: subclass("<" ## ?name ## ">")) => (class == "<unparsed-" ## ?name ## ">");
        "<unparsed-" ## ?name ## ">"
      end;

      define inline method decoded-class
       (type :: subclass("<" ## ?name ## ">")) => (class == "<decoded-" ## ?name ## ">");
        "<decoded-" ## ?name ## ">"
      end;

      define class "<unparsed-" ## ?name ## ">" ("<" ## ?name ## ">", "<unparsed-" ## ?superframe ## ">")
        inherited slot cache :: "<" ## ?name ## ">" = make("<" ## ?name ## "-cache>");
      end; }
end;

define macro unparsed-frame-field-generator
  { unparsed-frame-field-generator(?:name,
                                   ?frame-type:name,
                                   ?field-type:name,
                                   ?start:expression) }
 => { define inline method ?name (frame :: ?frame-type)
        frame.cache.?name |
          (if (?start = $unknown-at-compile-time)
             //parse full container frame
             frame.cache := parse-frame(frame.object-class, frame.packet, parent: frame.parent);
             frame.cache.?name;
           else
             frame.cache.?name := maybe-parse-frame(?field-type, ?start, frame.packet, frame);
           end)
       end;
       define sealed domain ?name (?frame-type); }
end;

define macro unparsed-frame-variable-field-generator
  { unparsed-frame-variable-field-generator(?:name,
                                            ?frame-type:name,
                                            ?field-type-function:expression,
                                            ?start:expression) }
 => { define inline method ?name (frame :: ?frame-type)
        frame.cache.?name |
          (if (?start = $unknown-at-compile-time)
             frame.cache := parse-frame(frame.object-class,
                                        frame.packet,
                                        parent: frame.parent);
             frame.cache.?name;
           else
             let field-type = ?field-type-function(frame);
             frame.cache.?name := maybe-parse-frame(field-type, ?start, frame.packet, frame);
           end)
       end;
       define sealed domain ?name (?frame-type); }
end;

define inline method maybe-parse-frame (frame-type :: subclass(<frame>),
                                 start :: <integer>,
                                 packet :: <byte-vector>,
                                 parent :: false-or(<container-frame>))
  maybe-parse-frame(frame-type, start, subsequence(packet), parent);
end;
define inline method maybe-parse-frame (frame-type :: subclass(<frame>),
                                 start :: <integer>,
                                 packet :: <byte-vector-subsequence>,
                                 parent :: false-or(<container-frame>))
  //find out end of subsequence -- start is always known at compile-time
  let packet-subsequence = subsequence(packet, start: byte-offset(start));
  if (subtype?(frame-type, <container-frame>))
    //we need to be byte-aligned?!
    make(unparsed-class(frame-type),
         packet: packet-subsequence,
         parent: parent);
  else
    parse-frame(frame-type, packet-subsequence, start: bit-offset(start), parent: parent);
  end
end;

define macro unparsed-frame-self-delimited-repeated-field-generator
  { unparsed-frame-self-delimited-repeated-field-generator
     (?:name, ?frame-type:name, ?field-type:name, ?start:expression, ?reached-end:expression) }
 => { define inline method ?name (frame :: ?frame-type)
        frame.cache.?name |
          (if (?start = $unknown-at-compile-time)
             frame.cache := parse-frame(frame.object-class, frame.packet, parent: frame.parent);
             frame.cache.?name;
           else
             frame.cache.?name := get-field-value(?#"name", frame);
           end)
       end;
       define sealed domain ?name (?frame-type);
       define inline method get-field-value (field-name == ?#"name",
                                      frame :: ?frame-type)
        => (res)
         //here we should have a lazy list which parses on demand
           //this will need information about field-type, start, fixed length,
           // fallback to runtime length, fallback to a parser state saved _somewhere_
         //also, lots of duplicated code as in parse-frame-aux()
         let res = make(<stretchy-vector>);
         let start = ?start;
         if (frame.packet.size > 0)
           let (value, offset) = parse-frame(?field-type, frame.packet, start: start, parent: frame);
           res := add!(res, value);
           start := offset;
           while ((~ ?reached-end(res.last)) & (byte-offset(start) < frame.packet.size))
             let (value, offset) = parse-frame(?field-type, frame.packet, start: start, parent: frame);
             start := offset;
             res := add!(res, value);
           end;
         end;
         res;
       end; }
end;

define macro unparsed-frame-count-repeated-field-generator
 { unparsed-frame-count-repeated-field-generator
    (?:name, ?frame-type:name, ?field-type:name, ?start:expression, ?count:expression) }
 => { define inline method ?name (frame :: ?frame-type)
        frame.cache.?name |
          (if (?start = $unknown-at-compile-time)
             frame.cache := parse-frame(frame.object-class, frame.packet, parent: frame.parent);
             frame.cache.?name;
           else
             frame.cache.?name := get-field-value(?#"name", frame);
           end)
       end;
       define sealed domain ?name (?frame-type);
       define inline method get-field-value (field-name == ?#"name",
                                      frame :: ?frame-type)
        => (res)
         let res = make(<stretchy-vector>);
         let start = ?start;
         if (frame.packet.size > 0)
           for (i from 0 below field.count(parent))
             let (value, offset) = parse-frame(?field-type, frame.packet, start: start, parent: frame);
             res := add!(res, value);
             start := offset;
           end;
         end;
         res;
       end; }
end;

define macro frame-field-generator
    { frame-field-generator(?type:name; ?count:*; field ?field-name:name \:: ?field-type:name  ; ?rest:*) }
    => { unparsed-frame-field-generator(?field-name, ?type, ?field-type, ?count);
         frame-field-generator(?type; ?count + field-size(?field-type); ?rest) }
    { frame-field-generator(?type:name; ?count:*; field ?field-name:name \:: ?field-type:name = ?init:expression ; ?rest:*) }
    => { unparsed-frame-field-generator(?field-name, ?type, ?field-type, ?count);
         frame-field-generator(?type; ?count + field-size(?field-type); ?rest) }
    { frame-field-generator(?type:name; ?count:*; field ?field-name:name \:: ?field-type:name, ?args:* ; ?rest:*) }
    => { unparsed-frame-field-generator(?field-name, ?type, ?field-type, ?count);
         frame-field-generator(?type; ?count + field-size(?field-type); ?rest) }
    { frame-field-generator(?type:name; ?count:*; variably-typed-field ?field-name:name, ?args:* ; ?rest:*) }
    => { unparsed-frame-variable-field-generator(?field-name, ?type, ?args, ?count);
         frame-field-generator(?type; $unknown-at-compile-time; ?rest) }
        //hmm, there might be fixed-size variably-typed-fields...
    { frame-field-generator(?type:name; ?count:*; repeated field ?field-name:name \:: ?field-type:name, reached-end?: ?reached:expression ; ?rest:*) }
    => { unparsed-frame-self-delimited-repeated-field-generator(?field-name, ?type, ?field-type, ?count, ?reached);
         frame-field-generator(?type; $unknown-at-compile-time; ?rest) }
    { frame-field-generator(?type:name; ?count:*; repeated field ?field-name:name \:: ?field-type:name, count: ?count2:expression ; ?rest:*) }
    => { unparsed-frame-count-repeated-field-generator(?field-name, ?type, ?field-type, ?count, ?count2);
         frame-field-generator(?type; $unknown-at-compile-time; ?rest) }
    { frame-field-generator(?:name; ?count:*) } => { }

  args:
    { } => { }
    { reached-end?: ?rest:expression, ...  } => { ?rest }
    { type-function: ?rest:expression, ... } => { method(?=frame :: <frame>) ?rest end }
    { ?key:token ?value:expression, ... } => { ... }
end;

define macro summary-generator
    { summary-generator(?type:name; ?summary-string:expression, ?summary-getters:*) }
    => { define method summary (frame :: ?type) => (result :: <string>);
           apply(format-to-string,
                 ?summary-string, 
                 map(method(x) frame.x end,
                     list(?summary-getters)));
         end; }
end;

define macro protocol-definer
    { define protocol ?:name (?superprotocol:name)
        summary ?summary:* ;
        ?fields:*
      end } =>
      { summary-generator("<" ## ?name ## ">"; ?summary);
        define protocol ?name (?superprotocol) ?fields end; }

    { define protocol ?:name (?superprotocol:name)
        ?fields:*
      end } =>
      { real-class-definer("<" ## ?name ## ">"; "<" ## ?superprotocol ## ">"; ?fields);
        cache-class-definer("<" ## ?name ## "-cache>";
                            "<" ## ?name ## ">", "<" ## ?superprotocol ## "-cache>";
                            ?fields);
        decoded-class-definer("<decoded-" ## ?name ## ">";
                              "<" ## ?name ## ">", "<decoded-" ## ?superprotocol ## ">";
                              ?fields);
        gen-classes(?name; ?superprotocol);
        frame-field-generator("<unparsed-" ## ?name ## ">"; 0; ?fields); }
end;

define macro leaf-frame-constructor-definer
  { define leaf-frame-constructor(?:name) end }
 =>
  {
    define method ?name (data :: <byte-vector>) 
     => (res :: "<" ## ?name ## ">");
      parse-frame("<" ## ?name ## ">", data)
    end;

    define method ?name (data :: <collection>)
     => (res :: "<" ## ?name ## ">");
      ?name(as(<byte-vector>, data))
    end;

    define method ?name (data :: <string>)
     => (res :: "<" ## ?name ## ">");
      read-frame("<" ## ?name ## ">", data)
    end;

  }
end;

