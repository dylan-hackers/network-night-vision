module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.


define method find-field (field-name :: <string>, list :: <simple-vector>)
 => (res :: false-or(<field>))
  find-field(as(<symbol>, field-name), list);
end;

define method find-field (name :: <symbol>, list :: <simple-vector>)
 => (res :: false-or(<field>))
  block(ret)
    for (field in list)
      if (field.field-name = name)
        ret(field)
      end;
    end;
    #f;
  end;
end;

define function compute-static-offset(list :: <simple-vector>)
  //input is a list of <field>
  //sets static-start, static-end, static-length for all fields
  let start = 0;
  for (field in list)
    if (start ~= $unknown-at-compile-time)
      unless (field.dynamic-start)
        if (field.static-start = $unknown-at-compile-time)
          field.static-start := start;
        else
          start := field.static-start;
        end;
      end;
    end;
    let my-length = static-field-size(field);
    if (my-length ~= $unknown-at-compile-time)
      unless (field.dynamic-length)
        if (field.static-length = $unknown-at-compile-time)
          field.static-length := my-length;
        else
          my-length := field.static-length;
        end;
      end;
    end;
    start := start + my-length;
    if (start ~= $unknown-at-compile-time)
      unless (field.dynamic-end)
        if (field.static-end = $unknown-at-compile-time)
          field.static-end := start;
        else
          start := field.static-end;
        end;
      end;
    end;
  end;
end;


define open generic field-size (frame :: subclass(<frame>))
 => (length :: <number>);

define inline method field-size (frame :: subclass(<frame>))
 => (length :: <unknown-at-compile-time>)
  $unknown-at-compile-time;
end;

define abstract class <field> (<object>)
  slot index :: <integer>, init-keyword: index:;
  constant slot field-name, required-init-keyword: name:;
  slot static-start :: <integer-or-unknown> = $unknown-at-compile-time, init-keyword: static-start:;
  slot static-length :: <integer-or-unknown> = $unknown-at-compile-time, init-keyword: static-length:;
  slot static-end :: <integer-or-unknown> = $unknown-at-compile-time, init-keyword: static-end:;
  slot init-value = #f, init-keyword: init-value:;
  constant slot fixup-function :: false-or(<function>) = #f, init-keyword: fixup:;
  constant slot getter, required-init-keyword: getter:;
  constant slot setter, required-init-keyword: setter:;
  constant slot dynamic-start :: false-or(<function>) = #f, init-keyword: dynamic-start:;
  constant slot dynamic-end :: false-or(<function>) = #f, init-keyword: dynamic-end:;
  constant slot dynamic-length :: false-or(<function>) = #f, init-keyword: dynamic-length:;
end;

define generic static-field-size (field :: <field>) => (res :: <integer-or-unknown>);

define method static-field-size (field :: <field>)
 => (res :: singleton($unknown-at-compile-time));
  $unknown-at-compile-time
end;

define abstract class <statically-typed-field> (<field>)
  slot type, required-init-keyword: type:;
end;

define class <single-field> (<statically-typed-field>)
end;

define method static-field-size (field :: <single-field>) => (res :: <integer-or-unknown>)
  field.type.field-size
end;

define class <variably-typed-field> (<field>)
  //type-function has to return a subclass of <container-frame>
  slot type-function, required-init-keyword: type-function:;
end;

define abstract class <repeated-field> (<statically-typed-field>)
end;

define class <self-delimited-repeated-field> (<repeated-field>)
  slot reached-end?, required-init-keyword: reached-end?:;
end;

define class <count-repeated-field> (<repeated-field>)
  slot count, required-init-keyword: count:;
end;

define method make(class == <repeated-field>,
                   #rest rest, 
                   #key count, reached-end?,
                   #all-keys)
 => (instance :: <repeated-field>);
  apply(make,
        if(count)
          <count-repeated-field>
        elseif(reached-end?)
          <self-delimited-repeated-field>
        else
          error("unsupported repeated field")
        end,
        count: count,
        reached-end?: reached-end?,
        rest);
end;

define generic assemble-field (frame :: <frame>, field :: <field>)
 => (packet :: <vector>);

define method assemble-field (frame :: <frame>,
                              field :: <statically-typed-field>)
 => (packet :: <vector>)
  assemble-frame-as(field.type, field.getter(frame))
end;

define method assemble-field (frame :: <frame>,
                              field :: <variably-typed-field>)
 => (packet :: <vector>)
  assemble-frame(field.getter(frame))
end;

define method assemble-field (frame :: <frame>,
                              field :: <repeated-field>)
 => (packet :: <vector>)
  apply(concatenate, map(curry(assemble-frame-as, field.type), field.getter(frame)))
end;


