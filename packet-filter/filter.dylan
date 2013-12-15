module: packet-filter
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define abstract class <filter-expression> (<object>)
end;

define generic matches? (packet :: <frame>, filter :: <filter-expression>)
  => (match? :: <boolean>);

define method matches? (packet :: <frame>, filter :: <filter-expression>)
 => (match? :: <boolean>)
  #f;
end;

define class <frame-present> (<filter-expression>)
  slot filter-frame-type :: <class>, required-init-keyword: type:;
end;

define method matches? (packet :: <container-frame>, filter :: <frame-present>)
 => (match? :: <boolean>)
  instance?(packet, filter.filter-frame-type);
end;

define method matches? (packet :: <header-frame>, filter :: <frame-present>)
 => (match? :: <boolean>)
  next-method() | matches?(packet.payload, filter)
end;

define class <field-equals> (<filter-expression>)
  slot filter-frame-type :: <class>, required-init-keyword: type:;
  slot filter-field-name :: <symbol>, required-init-keyword: name:;
  slot filter-field :: <field>, required-init-keyword: field:;
  slot filter-field-value, required-init-keyword: value:;
end;

define method matches? (packet :: <container-frame>, filter :: <field-equals>)
 => (match? :: <boolean>);
  instance?(packet, filter.filter-frame-type)
   & (filter.filter-field.getter(packet) = filter.filter-field-value)
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



