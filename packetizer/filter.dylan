module: packet-filter
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define abstract class <filter-expression> (<object>)
end;

define generic matches? (packet :: <frame>, filter :: <filter-expression>)
  => (match? :: <boolean>);

define method matches? (packet :: <frame>, filter :: <filter-expression>)
 => (match? :: <boolean>)
  #f;
end;
define class <frame-present> (<filter-expression>)
  slot frame-name :: <symbol>, required-init-keyword: frame:;
end;

define method matches? (packet :: <container-frame>, filter :: <frame-present>)
 => (match? :: <boolean>)
  if (as(<symbol>, packet.name) = filter.frame-name)
    #t;
  else
    #f;
  end;
end;

define method matches? (packet :: <header-frame>, filter :: <frame-present>)
 => (match? :: <boolean>)
  next-method() | matches?(packet.payload, filter)
end;

define class <field-equals> (<filter-expression>)
  slot frame-name :: <symbol>, required-init-keyword: frame:;
  slot field-name :: <symbol>, required-init-keyword: name:;
  slot field-value, required-init-keyword: value:;
end;

define method matches? (packet :: <container-frame>, filter :: <field-equals>)
  => (match? :: <boolean>);
  if (as(<symbol>, packet.name) = filter.frame-name)
    let field = choose(method(x) x.name == filter.field-name end,
                       packet.frame-fields);
    field.size > 0 
      & field.first.getter(packet) = read-frame(field.first.type, 
                                                filter.field-value);
  else
    #f
  end;
end;

define method matches? (packet :: <header-frame>, filter :: <field-equals>)
 => (match? :: <boolean>)
  next-method() | matches?(packet.payload, filter)
end;

define class <and-expression> (<filter-expression>)
  slot left-expression :: <filter-expression>, required-init-keyword: left:;
  slot right-expression :: <filter-expression>, required-init-keyword: right:;
end;

define method matches? (packet :: <frame>, filter :: <and-expression>)
  => (match? :: <boolean>);
  matches?(packet, filter.left-expression)
    & matches?(packet, filter.right-expression)
end;

define class <or-expression> (<filter-expression>)
  slot left-expression :: <filter-expression>, required-init-keyword: left:;
  slot right-expression :: <filter-expression>, required-init-keyword: right:;
end;

define method matches? (packet :: <frame>, filter :: <or-expression>)
  => (match? :: <boolean>);
  matches?(packet, filter.left-expression)
    | matches?(packet, filter.right-expression)
end;

define class <not-expression> (<filter-expression>)
  slot expression :: <filter-expression>, required-init-keyword: expression:;
end;

define method matches? (packet :: <frame>, filter :: <not-expression>)
  => (match? :: <boolean>);
  ~ matches?(packet, filter.expression)
end;



