module: packetizer-test

define function static-checker
  (field :: <field>,
   start :: <integer-or-unknown>,
   length :: <integer-or-unknown>,
   end-offset :: <integer-or-unknown>)
  check-equal(concatenate("Field ", as(<string>, field.name), " has static start"),
              start, field.static-start);
  check-equal(concatenate("Field ", as(<string>, field.name), " has static length"),
              length, field.static-length);
  check-equal(concatenate("Field ", as(<string>, field.name), " has static end"),
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
  let frame = make(unparsed-class(<test-protocol>),
                   packet: as(<byte-vector>, #(#x23, #x42)));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, 8, 16);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 8, 8, 16);
end;

define protocol dynamic-test (container-frame)
  field foobar :: <unsigned-byte>;
  field payload :: <raw-frame>,
    start: frame.foobar * 8;
end;

define test packetizer-dynamic-parser ()
  let frame = make(unparsed-class(<dynamic-test>),
                   packet: as(<byte-vector>, #(#x2, #x0, #x0, #x3, #x4, #x5)));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], $unknown-at-compile-time, $unknown-at-compile-time, $unknown-at-compile-time);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 16, 32, 48);
end;

define protocol static-start (container-frame)
  field a :: <unsigned-byte>;
  field b :: <raw-frame>, static-start: 24;
end;

define test static-start-test ()
  let frame = make(unparsed-class(<static-start>),
                   packet: as(<byte-vector>, #(#x3, #x4, #x5, #x6)));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 24, $unknown-at-compile-time, $unknown-at-compile-time);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 24, 8, 32);
end;  

define protocol repeated-test (container-frame)
  field foo :: <unsigned-byte>;
  repeated field bar :: <unsigned-byte>,
    reached-end?: method (frame) frame = 0 end;
  field after :: <unsigned-byte>;
end;

define test repeated-test ()
  let frame = make(unparsed-class(<repeated-test>),
                   packet: as(<byte-vector>, #(#x23, #x42, #x43, #x44, #x67, #x0, #x55)));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, $unknown-at-compile-time, $unknown-at-compile-time);
  static-checker(field-list[2], $unknown-at-compile-time, 8, $unknown-at-compile-time);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 8, 40, 48);
  frame-field-checker(2, frame, 48, 8, 56);
end;
  

define protocol repeated-and-dynamic-test (container-frame)
  field header-length :: <unsigned-byte>;
  field type-code :: <unsigned-byte>;
  repeated field options :: <unsigned-byte>,
    reached-end?: method(frame) frame = 0 end;
  field payload :: <raw-frame>,
    start: frame.header-length * 8;
end;

define test repeated-and-dynamic-test ()
  let frame = make(unparsed-class(<repeated-and-dynamic-test>),
                   packet: as(<byte-vector>, #(#x8, #x23, #x42, #x43, #x44, #x45,
                                               #x46, #x47, #x80, #x81, #x82)));
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
  let frame = make(unparsed-class(<repeated-and-dynamic-test>),
                   packet: as(<byte-vector>, #(#x8, #x23, #x42, #x43, #x44, #x0,
                                               #x46, #x47, #x80, #x81, #x82)));
  let field-list = fields(frame);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 8, 8, 16);
  frame-field-checker(2, frame, 16, 32, 48);
  frame-field-checker(3, frame, 64, 24, 88);
end;

define protocol count-repeated-test (container-frame)
  field foo :: <unsigned-byte>;
  repeated field fragments :: <unsigned-byte>,
    count: frame.foo;
  field last-field :: <unsigned-byte>;
end;

define test count-repeated-test ()
  let frame = make(unparsed-class(<count-repeated-test>),
                   packet: as(<byte-vector>, #(#x3, #x23, #x42, #x43, #x44, #x0,
                                               #x46, #x47, #x80, #x81, #x82)));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, $unknown-at-compile-time, $unknown-at-compile-time);
  static-checker(field-list[2], $unknown-at-compile-time, 8, $unknown-at-compile-time);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 8, 24, 32);
  frame-field-checker(2, frame, 32, 8, 40);
end;

define protocol frag (container-frame)
  field type-code :: <unsigned-byte>;
  field data-length :: <unsigned-byte>;
  field data :: <raw-frame>,
    length: frame.data-length * 8;
end;
define protocol labe (container-frame)
  field a :: <unsigned-byte>;
  repeated field b :: <frag>,
    reached-end?: method(frame) frame.data-length = 0 end;
  field c :: <unsigned-byte>;
end;

define test label-test ()
  let frame = make(unparsed-class(<labe>),
                   packet: as(<byte-vector>, #(#x23, #x42, #x01, #x02, #x42, #x03, #x33, #x33, #x33, #x42, #x00, #x42)));
  let field-list = fields(frame);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, $unknown-at-compile-time, $unknown-at-compile-time);
  static-checker(field-list[2], $unknown-at-compile-time, 8, $unknown-at-compile-time);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 8, 80, 88);
  frame-field-checker(2, frame, 88, 8, 96);
end;
define protocol a-super (container-frame)
  field type-code :: <unsigned-byte>;
end;

define protocol a-sub (a-super)
  field a :: <unsigned-byte>
end;

define test inheritance-test()
  let frame = make(unparsed-class(<a-sub>),
                   packet: as(<byte-vector>, #(#x23, #x42, #x23)));
  let field-list = fields(frame);
  check-equal("Field list has correct size",
              2, field-list.size);
  static-checker(field-list[0], 0, 8, 8);
  static-checker(field-list[1], 8, 8, 16);
  frame-field-checker(0, frame, 0, 8, 8);
  frame-field-checker(1, frame, 8, 8, 16);
end;
  
define protocol b-sub (a-super)
  field payload-length :: <unsigned-byte>;
  field payload :: <raw-frame>,
    length: frame.payload-length * 8;
end;

define test inheritance-dynamic-length()
  let aframe = make(unparsed-class(<b-sub>),
                    packet: as(<byte-vector>, #(#x23, #x3, #x0, #x0, #x0, #x42, #x42)));
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

define protocol c-sub (a-super)
  repeated field payload :: <b-sub>,
    reached-end?: method(frame) frame.payload-length = 0 end;
end;

define test inheritance-repeated-field()
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
end;

begin
  run-test-application(packetizer-suite, arguments: #("-debug"));
 // while(#t)
  //end;
end;

