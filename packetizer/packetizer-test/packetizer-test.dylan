module: packetizer-test
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define function static-checker
  (field :: <field>,
   start :: <integer-or-unknown>,
   length :: <integer-or-unknown>,
   end-offset :: <integer-or-unknown>)
  check-equal(concatenate("Field ", as(<string>, field.field-name), " has static start"),
              start, field.static-start);
  check-equal(concatenate("Field ", as(<string>, field.field-name), " has static length"),
              length, field.static-length);
  check-equal(concatenate("Field ", as(<string>, field.field-name), " has static end"),
              end-offset, field.static-end);
end;

define function frame-field-checker (field-index :: <integer>,
                                     frame :: <frame>,
                                     start :: <integer-or-unknown>,
                                     my-length :: <integer-or-unknown>,
                                     my-end :: <integer-or-unknown>)
  let frame-field = get-frame-field(field-index, frame);
  check-equal("Frame-field has start", start, frame-field.start-offset);
  check-equal("Frame-field has length", my-length, frame-field.length);
  check-equal("Frame-field has end", my-end, frame-field.end-offset);
end;

define protocol test-protocol (container-frame)
  field foo :: <unsigned-byte>;
  field bar :: <unsigned-byte>;
end;

define test packetizer-parser ()
  let frame = parse-frame(<test-protocol>, #(#x23, #x42));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, 8, 16);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 8, 8, 16);
end;

define test packetizer-assemble ()
  let frame = make(<test-protocol>, foo: #x23, bar: #x42);
  let byte-vector = assemble-frame(frame);
  check-equal("Assembled frame is correct", as(<byte-vector>, #(#x23, #x42)), byte-vector.packet);
end;
define test packetizer-modify ()
  let frame = parse-frame(<test-protocol>, #(#x23, #x42));
  frame.bar := #x69;
  let byte-vector = assemble-frame(frame);
  check-equal("Modified frame is correct", as(<byte-vector>, #(#x23, #x69)), byte-vector.packet);
end;

define protocol dynamic-test (header-frame)
  field foobar :: <unsigned-byte>;
  field payload :: <raw-frame>,
    start: frame.foobar * 8;
end;

define test packetizer-dynamic-parser ()
  let frame = parse-frame(<dynamic-test>, #(#x2, #x0, #x0, #x3, #x4, #x5));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], $unknown-at-compile-time, $unknown-at-compile-time, $unknown-at-compile-time);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 16, 32, 48);
end;

define test packetizer-dynamic-assemble ()
  let frame = make(<dynamic-test>,
                   foobar: #x3,
                   payload: parse-frame(<raw-frame>, as(<byte-vector>, #(#x23, #x42, #x23, #x42))));
  let byte-vector = assemble-frame(frame);
  check-equal("Assembling dynamic frame is correct (including padding)",
              as(<stretchy-byte-vector-subsequence>, #(#x3, #x0, #x0, #x23, #x42, #x23, #x42)),
              byte-vector.packet);
end;
define protocol static-start-frame (container-frame)
  field a :: <unsigned-byte>;
  field b :: <raw-frame>, static-start: 24;
end;

define test static-start-test ()
  let frame = parse-frame(<static-start-frame>, #(#x3, #x4, #x5, #x6));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 24, $unknown-at-compile-time, $unknown-at-compile-time);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 24, 8, 32);
end;  

define test static-start-assemble ()
  let frame = make(<static-start-frame>, a: #x23, b: parse-frame(<raw-frame>, as(<byte-vector>, #(#x2, #x3, #x4, #x5))));
  let byte-vector = assemble-frame(frame);
  check-equal("Assembling static start frame is correct (including padding)",
              as(<byte-vector>, #(#x23, #x0, #x0, #x2, #x3, #x4, #x5)),
              byte-vector.packet);
end;
define protocol repeated-test-frame (container-frame)
  field foo :: <unsigned-byte>;
  repeated field bar :: <unsigned-byte>,
    reached-end?: frame = 0;
  field after :: <unsigned-byte>;
end;

define test repeated-test ()
  let frame = parse-frame(<repeated-test-frame>, #(#x23, #x42, #x43, #x44, #x67, #x0, #x55));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, $unknown-at-compile-time, $unknown-at-compile-time);
  static-checker(field-list[2], $unknown-at-compile-time, 8, $unknown-at-compile-time);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 8, 40, 48);
  frame-field-checker(2, frame, 48, 8, 56);
end;

define test repeated-assemble ()
  let frame = make(<repeated-test-frame>,
                   foo: #x23,
                   bar: as(<stretchy-vector>, #(#x23, #x42, #x23, #x42, #x0)),
                   after: #x44);
  let byte-vector = assemble-frame(frame);
  check-equal("Assemble frame with repeated field",
              as(<byte-vector>, #(#x23, #x23, #x42, #x23, #x42, #x0, #x44)),
              byte-vector.packet);
end;

define protocol repeated-and-dynamic-test-frame (header-frame)
  field header-length :: <unsigned-byte>,
// FIXME:    fixup: byte-offset(frame-size(frame.header-length) + frame-size(frame.type-code) + frame-size(frame.options));
    fixup: frame.options.size + 2;
  field type-code :: <unsigned-byte> = #x23;
  repeated field options :: <unsigned-byte>,
    reached-end?: frame = 0;
  field payload :: <raw-frame>,
    start: frame.header-length * 8;
end;

define test repeated-and-dynamic-test ()
  let frame = parse-frame(<repeated-and-dynamic-test-frame>,
                          #(#x8, #x23, #x42, #x43, #x44, #x45, #x46, #x47, #x80, #x81, #x82));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, 8, 16);
  static-checker(field-list[2], 16, $unknown-at-compile-time, $unknown-at-compile-time);
  static-checker(field-list[3], $unknown-at-compile-time, $unknown-at-compile-time, $unknown-at-compile-time);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 8, 8, 16);
  frame-field-checker(2, frame, 16, 48, 64);
  frame-field-checker(3, frame, 64, 24, 88);
end;

define test repeated-and-dynamic-test2 ()
  let frame = parse-frame(<repeated-and-dynamic-test-frame>,
                          #(#x8, #x23, #x42, #x43, #x44, #x0, #x46, #x47, #x80, #x81, #x82));
  let field-list = fields(frame);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 8, 8, 16);
  frame-field-checker(2, frame, 16, 32, 48);
  frame-field-checker(3, frame, 64, 24, 88);
end;

define test repeated-and-dynamic-assemble ()
  let frame = make(<repeated-and-dynamic-test-frame>,
                   options: as(<stretchy-vector>, #(#x23, #x42, #x23, #x42, #x23, #x0)),
                   payload: parse-frame(<raw-frame>, as(<byte-vector>, #(#x0, #x1, #x2, #x3, #x4))));
  let byte-vector = assemble-frame(frame);
  check-equal("Repeated and dynamic assemble",
              as(<byte-vector>, #(#x8, #x23, #x23, #x42, #x23, #x42, #x23, #x0, #x0, #x1, #x2, #x3, #x4)),
              byte-vector.packet);
end;

define protocol count-repeated-test-frame (container-frame)
  field foo :: <unsigned-byte>,
    fixup: frame.fragments.size;
  repeated field fragments :: <unsigned-byte>,
    count: frame.foo;
  field last-field :: <unsigned-byte>;
end;

define test count-repeated-test ()
  let frame = parse-frame(<count-repeated-test-frame>,
                          #(#x3, #x23, #x42, #x43, #x44, #x0, #x46, #x47, #x80, #x81, #x82));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, $unknown-at-compile-time, $unknown-at-compile-time);
  static-checker(field-list[2], $unknown-at-compile-time, 8, $unknown-at-compile-time);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 8, 24, 32);
  frame-field-checker(2, frame, 32, 8, 40);
end;

define test count-repeated-assemble ()
  let frame = make(<count-repeated-test-frame>,
                   fragments: as(<stretchy-vector>, #(#x1, #x2, #x3, #x4, #x5, #x6, #x7)),
                   last-field: #x23);
  let byte-vector = assemble-frame(frame);
  check-equal("Count repeated assemble",
              as(<byte-vector>, #(#x7, #x1, #x2, #x3, #x4, #x5, #x6, #x7, #x23)),
              byte-vector.packet);
end;

define protocol frag (container-frame)
  field type-code :: <unsigned-byte> = #x23;
  field data-length :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame.data));
  field data :: <raw-frame>,
    length: frame.data-length * 8;
end;
define protocol labe (container-frame)
  field a :: <unsigned-byte>;
  repeated field b :: <frag>,
    reached-end?: frame.data-length = 0;
  field c :: <unsigned-byte>;
end;

define test label-test ()
  let frame = parse-frame(<labe>, #(#x23, #x42, #x01, #x02, #x42, #x03, #x33, #x33, #x33, #x42, #x00, #x42));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, $unknown-at-compile-time, $unknown-at-compile-time);
  static-checker(field-list[2], $unknown-at-compile-time, 8, $unknown-at-compile-time);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 8, 80, 88);
  frame-field-checker(2, frame, 88, 8, 96);
end;
define test label-assemble ()
  let frames = as(<stretchy-vector>,
                  list(make(<frag>, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x1, #x2, #x3)))),
                       make(<frag>, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x4, #x5, #x6)))),
                       make(<frag>, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x7, #x8, #x9, #x10))))));
  let frame = make(<labe>, a: #x23, b: frames, c: #x42);
  let byte-vector = assemble-frame(frame);
  check-equal("label assemble",
              as(<byte-vector>, #(#x23, #x23, #x3, #x1, #x2, #x3, #x23, #x3, #x4, #x5, #x6, #x23, #x4, #x7, #x8, #x9, #x10, #x42)),
              byte-vector.packet);
end;

define test label-assign1 ()
  let frames = as(<stretchy-vector>,
                  list(make(<frag>, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x1, #x2, #x3)))),
                       make(<frag>, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x4, #x5, #x6)))),
                       make(<frag>, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x7, #x8, #x9, #x10))))));
  let frame = make(<labe>, a: #x23, b: frames, c: #x42);
  frame.b[1] := make(<frag>, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x5, #x6, #x7))));
  let byte-vector = assemble-frame(frame);
  check-equal("label assign",
              as(<byte-vector>, #(#x23, #x23, #x3, #x1, #x2, #x3, #x23, #x3, #x5, #x6, #x7, #x23, #x4, #x7, #x8, #x9, #x10, #x42)),
              byte-vector.packet);
  frames[0] := make(<frag>, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x6, #x7, #x8))));
  byte-vector.b := frames;
  check-equal("label assign - 2",
              as(<byte-vector>, #(#x23, #x23, #x3, #x6, #x7, #x8, #x23, #x3, #x5, #x6, #x7, #x23, #x4, #x7, #x8, #x9, #x10, #x42)),
              byte-vector.packet);
  let fr2 = make(<labe>, a: #x42, b: byte-vector.b, c: #x23);
  let bv2 = assemble-frame(fr2);
  check-equal("label assign - 3",
              as(<byte-vector>, #(#x42, #x23, #x3, #x6, #x7, #x8, #x23, #x3, #x5, #x6, #x7, #x23, #x4, #x7, #x8, #x9, #x10, #x23)),
              bv2.packet);
  frames[0] := make(<frag>, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x10, #x11, #x12))));
  bv2.b := frames;
  frame-field-checker(1, bv2, 8, 128, 136);
  check-equal("label assign - 4",
              as(<byte-vector>, #(#x42, #x23, #x3, #x10, #x11, #x12, #x23, #x3, #x5, #x6, #x7, #x23, #x4, #x7, #x8, #x9, #x10, #x23)),
              bv2.packet);
end;

define test label-assign2 ()
  let frames = as(<stretchy-vector>,
                  list(make(<frag>, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x1, #x2, #x3)))),
                       make(<frag>, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x4, #x5, #x6)))),
                       make(<frag>, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x7, #x8, #x9, #x10))))));
  let frame = make(<labe>, a: #x23, b: frames, c: #x42);
  let byte-vector = assemble-frame(frame);
  let fr2 = make(<labe>, a: #x42, b: byte-vector.b, c: #x23);
  let bv2 = assemble-frame(fr2);
  frames[0] := make(<frag>, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x10, #x11))));
  bv2.b := frames;
  frame-field-checker(1, bv2, 8, 120, 128);
  frame-field-checker(2, bv2, 128, 8, 136);
  check-equal("bv2 has correct size", 17, bv2.packet.size);
  check-equal("label assign2",
              as(<byte-vector>, #(#x42, #x23, #x2, #x10, #x11, #x23, #x3, #x4, #x5, #x6, #x23, #x4, #x7, #x8, #x9, #x10, #x23)),
              bv2.packet);
end;

define test label-assign3 ()
  let fr = parse-frame(<labe>, as(<byte-vector>, #(#x42, #x23, #x2, #x10, #x11, #x23, #x3, #x4, #x5, #x6, #x23, #x4, #x7, #x8, #x9, #x10, #x23, #x00, #x23)));
  frame-field-checker(0, fr, 0, 8, 8);
  frame-field-checker(1, fr, 8, 136, 144);
  frame-field-checker(2, fr, 144, 8, 152);
  check-equal("a is #x42", #x42, fr.a);
  check-equal("c is #x23", #x23, fr.c);
  check-true("b is a collection", instance?(fr.b, <collection>));
  check-equal("b is of size 4", 4, size(fr.b));
  check-true("all of b are <frag>", every?(rcurry(instance?, <frag>), fr.b));
  check-true("frame-size of b is 136", reduce1(\+, map(frame-size, fr.b)));
  check-true("all of b are <unparsed-frag>", every?(rcurry(instance?, <unparsed-frag>), fr.b));
  check-true("fr is an <unparsed-labe>", instance?(fr, <unparsed-labe>));
  check-equal("sizes of bs are correct", as(<stretchy-vector>, #(32, 40, 48, 16)), map(frame-size, fr.b));
  let res = labe(a: fr.a, b: fr.b, c: fr.c);
  frame-field-checker(0, res, 0, 8, 8);
  frame-field-checker(1, res, 8, 136, 144);
  frame-field-checker(2, res, 144, 8, 152);
  let bv = assemble-frame(res);
  frame-field-checker(0, bv, 0, 8, 8);
  frame-field-checker(1, bv, 8, 136, 144);
  frame-field-checker(2, bv, 144, 8, 152);
  check-equal("size of bv is correct", 19, bv.packet.size);
  check-equal("label assign3",
              as(<byte-vector>, #(#x42, #x23, #x2, #x10, #x11, #x23, #x3, #x4, #x5, #x6, #x23, #x4, #x7, #x8, #x9, #x10, #x23, #x00, #x23)),
              bv.packet);
end;

define protocol a-super (container-frame)
  field type-code :: <unsigned-byte>;
end;

define protocol a-sub (a-super)
  field a :: <unsigned-byte>
end;

define test inheritance-test()
  let frame = parse-frame(<a-sub>, #(#x23, #x42, #x23));
  let field-list = fields(frame);
  check-equal("Field list has correct size",
              2, field-list.size);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, 8, 16);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 8, 8, 16);
end;

define test inheritance-assemble ()
  let frame = make(<a-sub>, type-code: #x42, a: #x23);
  let byte-vector = assemble-frame(frame);
  check-equal("inheritance assemble", as(<byte-vector>, #(#x42, #x23)), byte-vector.packet);
end;

define protocol b-sub (a-super)
  field payload-length :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame.data));
  field data :: <raw-frame>,
    length: frame.payload-length * 8;
end;

define test inheritance-dynamic-length()
  let aframe = parse-frame(<b-sub>, #(#x23, #x3, #x0, #x0, #x0, #x42, #x42));
  let field-list = fields(aframe);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, 8, 16);
  static-checker(field-list[2], 16, $unknown-at-compile-time, $unknown-at-compile-time);
  frame-field-checker(0, aframe, 0, 8, 8);
  frame-field-checker(1, aframe, 8, 8, 16);
  check-equal("Field size of <b-sub> is unknown",
              $unknown-at-compile-time, field-size(<b-sub>));
  frame-field-checker(2, aframe, 16, 24, 40);
end;

define protocol b-sub-sub (container-frame)
  field a :: <unsigned-byte>;
  field a* :: <raw-frame>,
    length: frame.a * 8;
  field b :: <unsigned-byte>;
end;

define test dyn-length ()
  let aframe = parse-frame(<b-sub-sub>, #(#x3, #x0, #x0, #x0, #x42, #x42));
  let field-list = fields(aframe);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, $unknown-at-compile-time, $unknown-at-compile-time);
  static-checker(field-list[2], $unknown-at-compile-time, 8, $unknown-at-compile-time);
  frame-field-checker(0, aframe, 0, 8, 8);
  frame-field-checker(1, aframe, 8, 24, 32);
  frame-field-checker(2, aframe, 32, 8, 40);
end;
define protocol b-subb (container-frame)
  //variably-typed-field data,
  //  type-function: <b-sub-sub>;
  field data :: <b-sub-sub>;
end;

define test dynamic-length ()
  let aframe = parse-frame(<b-subb>, #(#x3, #x0, #x0, #x0, #x42, #x42));
  let field-list = fields(aframe);
  static-checker(field-list[0], 0, $unknown-at-compile-time, $unknown-at-compile-time);
  frame-field-checker(0, aframe, 0, 40, 40);
end;

define test inheritance-dynamic-length-assemble ()
  let frame = make(<b-sub>, type-code: #x42, data: parse-frame(<raw-frame>, as(<byte-vector>, #(#x23, #x42, #x23, #x42))));
  let byte-vector = assemble-frame(frame);
  check-equal("Inheritance dynamic length assemble",
              as(<byte-vector>, #(#x42, #x4, #x23, #x42, #x23, #x42)),
              byte-vector.packet);
end;

define protocol half-byte-protocol (container-frame)
  field first-element :: <4bit-unsigned-integer> = #xf;
  field second-element :: <7bit-unsigned-integer> = #x7f;
end;

define test half-byte-parsing ()
  let frame = parse-frame(<half-byte-protocol>, #(#x23, #x42));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 4, 4);
  static-checker(field-list[1], 4, 7, 11);
  check-equal("first in half-byte has correct value", #x2, frame.first-element);
  check-equal("second in half-byte has correct value", #x1a, frame.second-element);
end;

define test half-byte-assembling ()
  let frame = make(<half-byte-protocol>,
                   first-element: #x2,
                   second-element: #x1a);
  let ff = assemble-frame(frame);
  check-equal("first byte is #x23", #x23, ff.packet[0]);
  check-equal("second byte is #x40", #x40, ff.packet[1]);
end;

define test half-byte-modify ()
  let frame = make(<half-byte-protocol>,
                   first-element: #x2,
                   second-element: #x1a);
  let ff = assemble-frame(frame);
  ff.first-element := #xf;
  check-equal("first byte is #xf3", #xf3, ff.packet[0]);
  check-equal("second byte is #x40", #x40, ff.packet[1]);
end;
define protocol half-bytes (container-frame)
  field a :: <4bit-unsigned-integer> = #xf;
  field b :: <4bit-unsigned-integer> = #x0;
  field c :: <4bit-unsigned-integer> = #x5;
  field d :: <4bit-unsigned-integer> = #xa;
end;

define test half-bytes-assembling ()
  let f = make(<half-bytes>);
  check-equal("f.a is #xf", #xf, f.a);
  check-equal("f.b is #x0", #x0, f.b);
  check-equal("f.c is #x5", #x5, f.c);
  check-equal("f.d is #xa", #xa, f.d);
  f.a := #xe;
  check-equal("f.a is #xe", #xe, f.a);
  let as = assemble-frame(f);
  check-equal("assembling is correct", #(#xe0, #x5a), as.packet);
end;

define protocol bits (container-frame)
  field a :: <1bit-unsigned-integer> = 0;
  field b :: <1bit-unsigned-integer> = 1;
  field c :: <1bit-unsigned-integer> = 0;
  field d :: <1bit-unsigned-integer> = 1;
  field e :: <1bit-unsigned-integer> = 0;
  field f :: <1bit-unsigned-integer> = 1;
end;

define test bits-assemble ()
  let f = make(<bits>);
  let as = assemble-frame(f);
  check-equal("assembling is correct", 84, as.packet[0]);
end;

define protocol dns-foo (container-frame)
  field typed :: <2bit-unsigned-integer> = 3;
  field pointer :: <14bit-unsigned-integer> = 42;
end;

define test dns-foo-parsing ()
  let frame = parse-frame(<dns-foo>, #(#xc0, #x4e));
  check-equal("type of frame is correct", 3, frame.typed);
  check-equal("pointer of frame is correct", #x4e, frame.pointer);
end;

define test dns-foo-assemble ()
  let f = make(<dns-foo>);
  let as = assemble-frame(f);
  check-equal("assembling of dns-foo[0] is correct", 192, as.packet[0]);
  check-equal("assembling of dns-foo[1] is correct", 42, as.packet[1]);
end;

define protocol dyn-length-in-container (container-frame)
  length frame.mylength * 8;
  field foo :: <unsigned-byte> = 0;
  field mylength :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame));
end;

define test dynlength ()
  let f = parse-frame(<dyn-length-in-container>, #(#x00, #x02));
  check-equal("length frame.my-length; size of simple frame is correct", 16, f.frame-size);
  let field-list = fields(f);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, 8, 16);
  frame-field-checker(0, f, 0, 8, 8);
  frame-field-checker(1, f, 8, 8, 16);
  let g = parse-frame(<dyn-length-in-container>, #(#x00, #x03, #x02));
  check-equal("length frame.my-length; size of frame with padding is correct", 24, g.frame-size);
  frame-field-checker(0, g, 0, 8, 8);
  frame-field-checker(1, g, 8, 8, 16);
  //this tells us: we need padding frame fields!
end;

define test dynlength-assemble ()
  let f = make(<dyn-length-in-container>);
  let as = assemble-frame(f);
  check-equal("assembling of dynlength[1] works correct", 2, as.packet[1]);
  let g = make(<dyn-length-in-container>, mylength: 3);
  let as = assemble-frame(g);
  //for now, I assume that padding does not need to work here this way
  //somehow, we should be able to add padding-frames to dynamically
  //length fields -- any takers on a pad api? --  Hannes, 18.1.2008
  check-equal("assembly of dynlength[0] works correct", 0, as.packet[0]);
  check-equal("assembly of dynlength[1] works correct", 3, as.packet[1]);
end;

define protocol dyn-length-as-client-field (container-frame)
  field first-foo :: <dyn-length-in-container>;
  field second-foo :: <dyn-length-in-container>;
end;

define test dyn-length-client ()
  let f = parse-frame(<dyn-length-as-client-field>, #(#x00, #x02, #x00, #x02));
  check-equal("size of dyn-length-client is correct", 32, f.frame-size);
  let field-list = fields(f);
  static-checker(field-list[0], 0, $unknown-at-compile-time, $unknown-at-compile-time);
  static-checker(field-list[1], $unknown-at-compile-time, $unknown-at-compile-time, $unknown-at-compile-time);
  frame-field-checker(0, f, 0, 16, 16);
  frame-field-checker(1, f, 16, 16, 32);
end;

define test dyn-length-client2 ()
  let f = parse-frame(<dyn-length-as-client-field>, #(#x00, #x03, #x04, #x00, #x04, #x01, #x02));
  check-equal("size of dyn-length-client2 is correct", 56, f.frame-size);
  frame-field-checker(0, f, 0, 24, 24);
  frame-field-checker(1, f, 24, 32, 56);
end;

define protocol enum-field-test (container-frame)
  enum field foobar :: <unsigned-byte>,
    mappings: { 1 <=> #"hello",
                2 <=> #"foobar" };
end;

define test enum-assemble-test ()
  let frame = make(<enum-field-test>, foobar: #"hello");
  check-equal("enum field value", #"hello", frame.foobar);
  let assembled-frame = assemble-frame(frame);
  check-equal("enum field value", 1, assembled-frame.packet[0]);
  assembled-frame.foobar := #"foobar";
  check-equal("enum field value", 2, assembled-frame.packet[0]);
  assembled-frame.foobar := 23;
  check-equal("enum field value", 23, assembled-frame.packet[0]);
end;

define test enum-parse-test ()
  let f = parse-frame(<enum-field-test>, #[#x01]);
  check-equal("enum field parses correct to symbol", #"hello", f.foobar);
  let g = parse-frame(<enum-field-test>, #[#x03]);
  check-equal("enum field parses correct to integer", 3, g.foobar);
  g.foobar := 23;
  check-equal("enum field parses correct to changed integer", 23, g.foobar);
  g.foobar := #"foobar";
  check-equal("enum field parses correct to changed symbol", #"foobar", g.foobar);
end;

define abstract protocol abstract-test (variably-typed-container-frame)
  layering field foo :: <unsigned-byte>;
end;

define protocol abstract-sub42 (abstract-test)
  over <abstract-test> 42;
  field bar :: <unsigned-byte> = 42;
end;

define protocol abstract-sub23 (abstract-test)
  over <abstract-test> 23;
  field foobar :: <unsigned-byte> = 23;
end;

define test abstract-parse-test ()
  let f = parse-frame(<abstract-test>, #(23, 42, 23));
  frame-field-checker(0, f, 0, 8, 8);
  frame-field-checker(1, f, 8, 8, 16);
  check-equal("type with inline layering is correct",
              #t, instance?(f, <abstract-sub23>));
end;

define test abstract-assemble-test ()
  let f = make(<abstract-sub42>);
  let as = assemble-frame(f);
  check-equal("assembling of abstract is ok", 42, as.packet[0]);
  check-equal("assembling of abstract is ok", 42, as.packet[0]);
end;
  
define protocol abstract-user (container-frame)
  repeated field abstracts :: <abstract-test>,
    reached-end?: instance?(frame, <abstract-sub23>);
end;

define test abstract-user-parse-test ()
  let f = parse-frame(<abstract-user>, #(42, 42, 42, 42, 42, 42, 23, 23));
  frame-field-checker(0, f, 0, 64, 64);
  check-equal("abstract count is 4", 4, f.abstracts.size);
  check-equal("repeated1 is 42", #t, instance?(f.abstracts[0], <abstract-sub42>));
  check-equal("repeated2 is 42", #t, instance?(f.abstracts[1], <abstract-sub42>));
  check-equal("repeated3 is 42", #t, instance?(f.abstracts[2], <abstract-sub42>));
  check-equal("repeated4 is 23", #t, instance?(f.abstracts[3], <abstract-sub23>));
end;

define test abstract-user-assemble-test ()
  let f = make(<abstract-user>,
               abstracts: list(make(<abstract-sub42>),
                               make(<abstract-sub42>),
                               make(<abstract-sub42>),
                               make(<abstract-sub42>),
                               make(<abstract-sub23>)));
  check-equal("frame size of abstract-user is correct", 80, frame-size(f));
  let as = assemble-frame(f);
  check-equal("byte1 of abstract-user is correct", 42, as.packet[0]);
  check-equal("byte2 of abstract-user is correct", 42, as.packet[1]);
  check-equal("byte3 of abstract-user is correct", 42, as.packet[2]);
  check-equal("byte4 of abstract-user is correct", 42, as.packet[3]);
  check-equal("byte5 of abstract-user is correct", 42, as.packet[4]);
  check-equal("byte6 of abstract-user is correct", 42, as.packet[5]);
  check-equal("byte7 of abstract-user is correct", 42, as.packet[6]);
  check-equal("byte8 of abstract-user is correct", 42, as.packet[7]);
  check-equal("byte9 of abstract-user is correct", 23, as.packet[8]);
  check-equal("byte10 of abstract-user is correct", 23, as.packet[9]);
end;

define suite packetizer-suite ()
  test packetizer-parser;
  test packetizer-dynamic-parser;
  test static-start-test;
  test repeated-test;
  test repeated-and-dynamic-test;
  test repeated-and-dynamic-test2;
  test count-repeated-test;
  test label-test;
  test inheritance-test;
  test inheritance-dynamic-length;
  test dyn-length;
  test dynamic-length;
  test half-byte-parsing;
  test dns-foo-parsing;
  test dynlength;
  test dyn-length-client;
  test dyn-length-client2;
  test enum-parse-test;
  test abstract-parse-test;
  test abstract-user-parse-test;
end;

define suite packetizer-assemble-suite ()
  test packetizer-assemble;
  test packetizer-modify;
  test packetizer-dynamic-assemble;
  test static-start-assemble;
  test repeated-assemble;
  test repeated-and-dynamic-assemble;
  test count-repeated-assemble;
  test label-assemble;
  test label-assign1;
  //test label-assign2;
  test label-assign3;
  test inheritance-assemble;
  test inheritance-dynamic-length-assemble;
  test half-byte-assembling;
  test half-byte-modify;
  test half-bytes-assembling;
  test bits-assemble;
  test dns-foo-assemble;
  test dynlength-assemble;
  test enum-assemble-test;
  test abstract-assemble-test;
  test abstract-user-assemble-test;
end;

begin
  run-test-application(packetizer-suite); //, arguments: #("-debug"));
  run-test-application(packetizer-assemble-suite); //, arguments: #("-debug"));
end;

