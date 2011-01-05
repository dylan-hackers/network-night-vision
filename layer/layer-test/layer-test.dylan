Module:    layer-test
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in the parent directory


define layer simple-layer
  property a :: <integer> = 23;
end;

define test simple-layer-basic ()
  let a = make(<simple-layer>);
  check-instance?("a is instance of simple-layer", <simple-layer>, a);
  check-equal("layer name is simple-layer0", #"simple-layer0", a.layer-name);
  check-equal("property a is 23", 23, a.@a);
  let p = get-property(a, #"a");
  check-instance?("p is a property", <property>, p);
  check-equal("property name is correct", #"a", p.property-name);
  check-equal("property type is correct", <integer>, p.property-type);
  check-equal("property value is correct", 23, p.property-value);
  check-equal("property default value is correct", 23, p.property-default-value);
  check-equal("property owner is correct", a, p.property-owner);

  set-property-value(a, #"a", 42);
  check-equal("property value is correct after set-property", 42, p.property-value);
end;

define test simple-layer-with-default ()
  let a = make(<simple-layer>, a: 42);
  check-equal("property value is 42", 42, a.@a);
  check-equal("default-value is 42", 42, get-property(a, #"a").property-default-value);
end;

define test simple-layer-callback ()
  let callback-called? = #f;
  let a = make(<simple-layer>);
  register-event(a, #"a", method(c) callback-called? := #t end);
  a.@a := 42;
  check-true("callback called", callback-called?);
end;

define test simple-layer-null-callback ()
  let callback-called? = #f;
  let a = make(<simple-layer>);
  register-event(a, #"a", method(c) callback-called? := #t end);
  a.@a := 23;
  check-false("callback not called", callback-called?);
end;

define test simple-layer-null-callback-2 ()
  let callback-called? = #f;
  let a = make(<simple-layer>);
  register-event(a, #"a", method(c) callback-called? := #t end);
  a.@a := 23;
  check-false("callback not called", callback-called?);
  a.@a := 42;
  check-true("callback called", callback-called?);
end;

define test simple-layer-callback-with-deregister ()
  let callback-called? = #f;
  let a = make(<simple-layer>);
  let callback = method(c) callback-called? := #t end;
  register-event(a, #"a", callback);
  a.@a := 23;
  check-false("callback not called", callback-called?);
  deregister-event(a, #"a", callback);
  a.@a := 42;
  check-false("callback also not called", callback-called?);
end;

define suite layer-suite ()
  test simple-layer-basic;
  test simple-layer-with-default;
  test simple-layer-callback;
  test simple-layer-null-callback;
  test simple-layer-null-callback-2;
  test simple-layer-callback-with-deregister;
end;

begin
  run-test-application(layer-suite);
end;
