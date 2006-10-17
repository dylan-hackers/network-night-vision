module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.


define class <malformed-packet-error> (<error>)
end;

define class <alignment-error> (<error>)
end;

define class <out-of-range-error> (<error>)
end;

define class <parse-error> (<error>)
end;

define class <unknown-at-compile-time> (<number>)
end;

define constant $unknown-at-compile-time = make(<unknown-at-compile-time>);

define constant <integer-or-unknown> = type-union(<integer>,
                                                  singleton($unknown-at-compile-time));
define sealed domain \+ (<integer-or-unknown>, <unknown-at-compile-time>);
define sealed domain \+ (<unknown-at-compile-time>, <integer-or-unknown>);
define sealed domain \+ (<unknown-at-compile-time>, <unknown-at-compile-time>);

define method \+ (a :: <integer-or-unknown>, b :: <unknown-at-compile-time>)
 => (res :: singleton($unknown-at-compile-time))
  $unknown-at-compile-time
end;

define method \+ (a :: <unknown-at-compile-time>, b :: <integer-or-unknown>)
 => (res :: singleton($unknown-at-compile-time))
  $unknown-at-compile-time
end;

define method \+ (a :: <unknown-at-compile-time>, b :: <unknown-at-compile-time>)
 => (res :: singleton($unknown-at-compile-time))
  $unknown-at-compile-time
end;

define constant <byte-sequence> = <stretchy-vector-subsequence>;
define constant <bit-vector> = <stretchy-bit-vector-subsequence>;

define constant $protocols = make(<table>);

define method find-protocol-aux (protocol :: <string>)
 => (res :: false-or(<simple-vector>))
  find-protocol-aux(as(<symbol>, protocol));
end;

define method find-protocol-aux (protocol :: <symbol>)
 => (res :: false-or(<simple-vector>))
  element($protocols, protocol, default: #f);
end;

define function find-protocol (name :: <string>)
 => (res :: <simple-vector>, frame-name :: <string>)
  let protocol-name = name;
  let res = find-protocol-aux(protocol-name);
  unless(res)
    protocol-name := concatenate("<", name, ">");
    res := find-protocol-aux(protocol-name);
    unless(res)
      protocol-name := concatenate("<", name, "-frame>");
      res := find-protocol-aux(protocol-name);
      unless(res)
        error("Protocol not found %s\n", name);
      end;
    end;
  end;
  values(res, protocol-name);
end;

define function find-protocol-field (protocol-name :: <string>, field-name :: <string>)
 => (res :: <field>, frame-name :: <string>)
  let (protocol-fields, frame-name) = find-protocol(protocol-name);
  let field = find-field(field-name, protocol-fields);
  if (field)
    values(field, frame-name);
  else
    error("Field %s in protocol %s not found\n", field-name, protocol-name);
  end;
end;

define abstract class <frame> (<object>)
end;

define open generic parse-frame
  (frame-type :: subclass (<frame>),
   packet :: <sequence>,
   #rest rest, #key, #all-keys);

define method parse-frame
  (frame-type :: subclass (<frame>),
   packet :: <byte-vector>,
   #rest rest,
   #key, #all-keys)
 => (value :: <object>, next-unparsed :: false-or(<integer>));
 let packet-subseq = subsequence(as(<stretchy-byte-vector-subsequence>, packet));
 apply(parse-frame, frame-type, packet-subseq, rest);
end;


define generic assemble-frame-into (frame :: <frame>,
                                    packet :: <stretchy-vector-subsequence>) => (length :: <integer>);

define generic assemble-frame
  (frame :: <frame>) => (packet /* :: <vector> */);

define method assemble-frame
  (frame :: <unparsed-container-frame>) => (packet :: <unparsed-container-frame>)
  frame;
end;

define generic assemble-frame-as
    (frame-type :: subclass(<frame>), data :: <object>) => (packet /* :: <vector> */);

define method assemble-frame-as
    (frame-type :: subclass(<frame>), data :: <object>) => (packet /* :: <byte-vector> */);
  if (instance?(data, frame-type))
    assemble-frame(data)
  else
    error("Don't know how to convert representation!")
  end
end;

define generic print-frame (frame :: <frame>, stream :: <stream>) => ();

define method print-frame (frame :: <frame>, stream :: <stream>) => ();
  write(stream, as(<string>, frame))
end;

define open generic high-level-type (low-level-type :: subclass(<frame>)) => (res :: <type>);

define inline method high-level-type (object :: subclass(<frame>)) => (res :: <type>)
  object
end;

define open generic fixup! (frame :: type-union(<container-frame>, <raw-frame>));

define method fixup!(frame :: type-union(<container-frame>, <raw-frame>))
end;

define method fixup!(frame :: <header-frame>)
  fixup!(frame.payload);
end;

define generic frame-size (frame :: type-union(<frame>, subclass(<fixed-size-frame>)))
 => (length :: <integer>);

define open generic summary (frame :: <frame>) => (summary :: <string>);

define method summary (frame :: <frame>) => (summary :: <string>)
  format-to-string("%=", frame.object-class);
end;

define abstract class <fixed-size-frame> (<frame>)
end;

define inline method frame-size (frame :: subclass(<fixed-size-frame>))
 => (length :: <integer>)
  field-size(frame);
end;

define inline method frame-size (frame :: <fixed-size-frame>)
 => (length :: <integer>)
  field-size(frame.object-class);
end;

define abstract class <variable-size-frame> (<frame>)
end;

define abstract class <untranslated-frame> (<frame>)
end;

define abstract class <translated-frame> (<frame>)
end;

define abstract class <fixed-size-untranslated-frame>
    (<fixed-size-frame>, <untranslated-frame>)
end;

define abstract class <variable-size-untranslated-frame>
    (<variable-size-frame>, <untranslated-frame>)
end;

define open abstract class <container-frame> (<variable-size-untranslated-frame>)
  virtual constant slot frame-name :: <string>;
end;

define open generic frame-name (frame :: type-union(subclass(<container-frame>), <container-frame>)) => (res :: <string>);

define inline method frame-name (frame :: <container-frame>) => (res :: <string>)
  frame-name(frame.object-class);
end;

define method frame-name(frame :: subclass(<container-frame>)) => (res :: <string>)
  "anonymous"
end;

define open generic source-address (frame :: type-union(<raw-frame>, <container-frame>)) => (res);

define open generic destination-address (frame :: type-union(<raw-frame>, <container-frame>)) => (res);

define open generic payload-type (frame :: type-union(<raw-frame>, <container-frame>)) => (res);

define open generic field-count (frame :: subclass(<container-frame>))
 => (res :: <integer>);

define inline method field-count (frame :: subclass(<container-frame>))
 => (res :: <integer>)
  field-count(unparsed-class(frame));
end;

define inline method field-count (frame :: subclass(<unparsed-container-frame>))
 => (res :: <integer>)
  0;
end;

define open generic fields (frame :: <container-frame>)
 => (res :: <simple-vector>);

define open generic fields-initializer (frame :: subclass(<container-frame>))
 => (res :: <simple-vector>);

define inline method fields-initializer (frame :: subclass(<container-frame>))
 => (fields :: <simple-vector>)
  as(<simple-object-vector>, #[]);
end;

define open generic unparsed-class (type :: subclass(<container-frame>))
  => (class :: <class>);

define open generic decoded-class (type :: subclass(<container-frame>))
  => (class :: <class>);

define open abstract class <decoded-container-frame> (<container-frame>)
  slot concrete-frame-fields :: <vector>;
  slot parent :: false-or(<container-frame>) = #f, init-keyword: parent:;
end;

define method initialize (frame :: <decoded-container-frame>,
                          #rest rest, #key, #all-keys)
  next-method();
  frame.concrete-frame-fields := make(<vector>, size: field-count(frame.object-class), fill: #f);
end;

define open abstract class <unparsed-container-frame> (<container-frame>)
  slot packet :: <byte-sequence>, init-keyword: packet:;
  slot cache :: <container-frame>, init-keyword: cache:;
end;

define method make (class :: subclass(<unparsed-container-frame>),
                    #next next-method, #rest rest, #key packet, parent, #all-keys)
 => (res :: <unparsed-container-frame>)
  if (instance?(packet, <byte-vector>))
    let packet = as(<stretchy-byte-vector-subsequence>, packet);
    replace-arg(rest, #"packet", packet);
  end;
  apply(next-method, class, rest);
end;
define method initialize (class :: <unparsed-container-frame>,
                          #rest rest, #key parent, #all-keys)
  next-method();
  parent-setter(parent, class.cache);
end;
define inline method concrete-frame-fields (frame :: <unparsed-container-frame>) => (res :: <vector>)
  frame.cache.concrete-frame-fields;
end;

define inline method parent (frame :: <unparsed-container-frame>) => (res :: false-or(<container-frame>))
  frame.cache.parent;
end;

define inline method parent-setter (value :: false-or(<container-frame>), frame :: <unparsed-container-frame>) => (res :: false-or(<container-frame>))
  frame.cache.parent := value;
end;

define method get-frame-field (field-index :: <integer>, frame :: <container-frame>)
 => (res :: <frame-field>)
  let res = frame.concrete-frame-fields[field-index];
  if (res)
    res;
  else
    let frame-field = make(<frame-field>,
                           frame: frame,
                           field: fields(frame)[field-index]);
    frame.concrete-frame-fields[field-index] := frame-field;
    frame-field;
  end;
end;

define method get-frame-field (name :: <symbol>, frame :: <container-frame>)
 => (res :: <frame-field>)
  let field = find-field(name, fields(frame));
  get-frame-field(field.index, frame)
end;

define function sorted-frame-fields (frame :: <container-frame>)
  map(method(x) get-frame-field(x.field-name, frame) end,
      fields(frame))
end;

define open abstract class <header-frame> (<container-frame>)
end;

define open abstract class <decoded-header-frame>
  (<header-frame>, <decoded-container-frame>)
end;

define open abstract class <unparsed-header-frame>
  (<header-frame>, <unparsed-container-frame>)
end;

define open generic payload (frame :: <header-frame>);

define method payload (frame :: <header-frame>) => (payload :: <frame>)
  error("No payload specified");
end;

define method frame-size (frame :: <container-frame>) => (res :: <integer>)
  reduce1(\+, map(curry(get-field-size-aux, frame), frame.fields));
end;

define method assemble-frame (frame :: <container-frame>) => (packet :: <unparsed-container-frame>);
  let result = make(<stretchy-byte-vector-subsequence>, data: make(<stretchy-byte-vector>, capacity: 1548));
  assemble-frame-into(frame, result);
  let uf = make(unparsed-class(frame.object-class), cache: frame, packet: result);
  fixup!(uf);
  uf;
end;

define method as(type == <string>, frame :: <container-frame>) => (string :: <string>);
  apply(concatenate,
        format-to-string("%=\n", frame.object-class),
        map(method(field :: <field>)
              let field-value = field.getter(frame);
              let field-as-string 
                = if (instance?(field-value, <collection>))
                    reduce(method(x, y) concatenate(x, " ", as(<string>, y)) end,
                           "", field-value)
                  else
                    as(<string>, field-value)
                  end;
              concatenate(as(<string>, field.field-name),
                          ": ",
                          field-as-string,
                          "\n")
            end, fields(frame)))
end;

define method assemble-frame-into (frame :: <container-frame>,
                                   packet :: <stretchy-vector-subsequence>) => (res :: <integer>)
  let offset :: <integer> = 0;
  for (field in fields(frame))
    unless (field.getter(frame))
      if (field.fixup-function)
        field.setter(field.fixup-function(frame), frame);
      else
        error("No value for field %s while assembling", field.field-name);
      end;
    end;
    if (field.dynamic-start)
      let real-frame-start = field.dynamic-start(frame);
      if (real-frame-start ~= offset)
        //pad!
        format-out("Need dynamic padding at start of %s : %d ~= %d\n",
                   field.field-name, real-frame-start, offset);
      end;
      offset := real-frame-start;
    end;
    if ((field.static-start ~= $unknown-at-compile-time) & (field.static-start ~= offset))
      format-out("Need static padding at start of %s : %d ~= %d\n",
                 field.field-name, field.static-start, offset);
      offset := field.static-start;
    end;
    let length = offset + assemble-field-into(field, frame, subsequence(packet, start: offset));
    frame.concrete-frame-fields[field.index].%start-offset := offset;
    if (instance?(field.getter(frame), <container-frame>))
      let unparsed = make(unparsed-class(field.getter(frame).object-class),
                          cache: field.getter(frame),
                          packet: subsequence(packet, start: offset, length: length),
                          parent: frame);
      field.setter(unparsed, frame);
    end;
    if (field.dynamic-end)
      let real-frame-end = field.dynamic-end(frame);
      if (real-frame-end ~= length)
        //pad!
        format-out("Need dynamic padding at end of %s : %d ~= %d\n",
                   field.field-name, real-frame-end, length);
      end;
      length := real-frame-end;
    end;
    if ((field.static-end ~= $unknown-at-compile-time) & (field.static-end ~= length))
      format-out("Need static padding at end of %s : %d ~= %d\n",
                 field.field-name, field.static-end, length);
      offset := field.static-end;
    end;
    offset := length;
  end;
  offset;
end;

define method assemble-frame-into (frame :: <unparsed-container-frame>,
                                   to-packet :: <stretchy-vector-subsequence>) => (res :: <integer>)
  copy-bytes(frame.packet, 0, to-packet, 0, frame.packet.size);
  frame.packet.size * 8;
end;

define method assemble-field-into(field :: <single-field>,
                                  frame :: <container-frame>,
                                  packet :: <stretchy-vector-subsequence>)
  let length = assemble-aux(field.type, field.getter(frame), packet);
  let ff = make(<frame-field>, field: field, frame: frame, length: length);
  frame.concrete-frame-fields[field.index] := ff;
  length;
end;

define method assemble-field-into(field :: <variably-typed-field>,
                                  frame :: <container-frame>,
                                  packet :: <stretchy-vector-subsequence>)
  let length = assemble-frame-into(field.getter(frame), packet);
  let ff = make(<frame-field>, field: field, frame: frame, length: length);
  frame.concrete-frame-fields[field.index] := ff;
  length;
end;

define method assemble-field-into(field :: <repeated-field>,
                                  frame :: <container-frame>,
                                  packet :: <stretchy-vector-subsequence>)
  let offset :: <integer> = 0;
  let repeated-ff = make(<repeated-frame-field>, field: field, frame: frame);
  for (ele in field.getter(frame))
    let length = assemble-aux(field.type, ele, subsequence(packet, start: offset));
    let ff = make(<rep-frame-field>, start: offset, parent: repeated-ff, frame: frame, end: length);
    add!(repeated-ff.frame-field-list, ff);
    offset := length + offset;
  end;
  repeated-ff.%length := offset;
  frame.concrete-frame-fields[field.index] := repeated-ff;
  offset;
end;

define method assemble-aux (frame-type :: subclass(<untranslated-frame>),
                            frame :: <frame>,
                            packet :: <stretchy-vector-subsequence>) => (res :: <integer>)
  assemble-frame-into(frame, packet);
end;

define method assemble-aux (frame-type :: subclass(<translated-frame>),
                            frame :: <object>,
                            packet :: <stretchy-vector-subsequence>) => (res :: <integer>)
  assemble-frame-into-as(frame-type, frame, packet);
end;

define open abstract class <position-mixin> (<object>)
  slot %start-offset :: false-or(<integer>) = #f, init-keyword: start:;
  slot %end-offset :: false-or(<integer>) = #f, init-keyword: end:;
  slot %length :: false-or(<integer>) = #f, init-keyword: length:;
end;

define class <rep-frame-field> (<position-mixin>)
  constant slot parent-frame-field :: <frame-field>, required-init-keyword: parent:;
  constant slot frame, required-init-keyword: frame:;
end;

define inline method start-offset (ff :: <position-mixin>)
  ff.%start-offset;
end;

define inline method end-offset (ff :: <position-mixin>)
  ff.%end-offset;
end;

define inline method length (ff :: <position-mixin>)
  ff.%length;
end;

define class <frame-field> (<position-mixin>)
  constant slot field :: <field>, init-keyword: field:;
  constant slot frame :: <container-frame>, init-keyword: frame:;
end;

define class <repeated-frame-field> (<frame-field>)
  slot frame-field-list :: <stretchy-vector> = make(<stretchy-vector>);
end;

define method make (class == <frame-field>, #rest rest, #key field, #all-keys) => (res :: <frame-field>)
  if (instance?(field, <repeated-field>))
    apply(make, <repeated-frame-field>, field: field, rest);
  else
    next-method();
  end;
end;

define inline method value (frame-field :: <frame-field>) => (res)
  frame-field.field.getter(frame-field.frame);
end;

define inline method start-offset (frame-field :: <frame-field>) => (res :: <integer>)
  unless (frame-field.%start-offset)
    let my-field = frame-field.field;
    if (my-field.static-start ~= $unknown-at-compile-time)
      frame-field.%start-offset := my-field.static-start;
      if (my-field.dynamic-start)
        error("found a gap: in %s knew start offset statically (%d), but got a dynamic offset (%d)\n",
              my-field.field-name, my-field.static-start, my-field.dynamic-start(frame-field.frame))
      end;
    elseif (my-field.dynamic-start)
      frame-field.%start-offset := my-field.dynamic-start(frame-field.frame);
    else
      if (my-field.index > 0)
        frame-field.%start-offset
          := end-offset(get-frame-field(my-field.index - 1, frame-field.frame));
      end;
    end;
  end;
  frame-field.%start-offset
end;

define inline function compute-field-length (frame-field :: <frame-field>) => (res :: false-or(<integer>))
  let my-field = frame-field.field;
  if (my-field.static-length ~= $unknown-at-compile-time)
    frame-field.%length := my-field.static-length;
    if (my-field.dynamic-length)
      error("found a gap: in %s knew length statically (%d), but got a dynamic offset (%d)\n",
            my-field.field-name, my-field.static-length, my-field.dynamic-length(frame-field.frame))
    end;
  elseif (my-field.dynamic-length)
    frame-field.%length := my-field.dynamic-length(frame-field.frame);
  end;
  frame-field.%length;
end;

define inline method length (frame-field :: <frame-field>) => (res :: <integer>)
  unless (frame-field.%length)
    unless (compute-field-length(frame-field))
      value(frame-field); //XXX: b0rk3n
      unless (frame-field.%length)
        frame-field.%length := get-field-size-aux(frame-field.frame, frame-field.field);
      end;
    end;
  end;
  frame-field.%length;
end;

define inline function compute-field-end (frame-field :: <frame-field>) => (res :: false-or(<integer>))
  let my-field = frame-field.field;
  if (my-field.static-end ~= $unknown-at-compile-time)
    frame-field.%end-offset := my-field.static-end;
    if (my-field.dynamic-end)
      error("found a gap: in %s knew end statically (%d), but got a dynamic end (%d)\n",
            my-field.field-name, my-field.static-end, my-field.dynamic-end(frame-field.frame));
    end;
  elseif (my-field.dynamic-end)
    frame-field.%end-offset := my-field.dynamic-end(frame-field.frame);
  end;
  frame-field.%end-offset;
end;

define inline method end-offset (frame-field :: <frame-field>) => (res :: <integer>)
  unless (frame-field.%end-offset)
    unless (compute-field-end(frame-field))
      frame-field.%end-offset := frame-field.start-offset + frame-field.length;
    end;
  end;
  frame-field.%end-offset;
end;

define sideways method print-object (frame-field :: <frame-field>, stream :: <stream>) => ();
  format(stream, "%s: %=", frame-field.field.field-name, frame-field.frame)
end;

define method get-field-size-aux (frame :: <container-frame>, field :: <statically-typed-field>)
 => (size :: <integer>)
  get-field-size-aux-aux(frame, field, field.type);
end;

define method get-field-size-aux (frame :: <container-frame>, field :: <variably-typed-field>)
 => (size :: <integer>)
  frame-size(field.getter(frame));
end;

define method get-field-size-aux (frame :: <container-frame>, field :: <repeated-field>)
  reduce(\+, 0, map(frame-size, field.getter(frame)));
end;

define method get-field-size-aux-aux (frame :: <frame>,
                                      field :: <single-field>,
                                      frame-type :: subclass(<fixed-size-frame>))
 => (res :: <integer>)
  frame-size(frame-type);
end;

define method get-field-size-aux-aux (frame :: <frame>,
                                      field :: <single-field>,
                                      frame-type :: subclass(<variable-size-untranslated-frame>))
 => (res :: <integer>)
  frame-size(field.getter(frame))
end;

define method get-field-size-aux-aux (frame :: <frame>,
                                      field :: <single-field>,
                                      frame-type :: subclass(<variable-size-translated-leaf-frame>))
 => (res :: <integer>)
  //need to look for user-defined static size method
  //or assemble frame, cache it and get its size
  error("Not yet implemented!")
end;

