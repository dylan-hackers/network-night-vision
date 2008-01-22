Module:    dylan-user
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define module packetizer
  use common-dylan, exclude: { format-to-string };
  use dylan-extensions, import: { \copy-down-method-definer };
  use format;
  use format-out;
  use standard-io;
  use streams;
  use print, import: { print-object };
  use date;
  use byte-vector;

  // Add binding exports here.
  export <stretchy-vector-subsequence>,
    <stretchy-byte-vector-subsequence>,
    subsequence,
    start-index, end-index,
    <out-of-bound-error>,
    encode-integer, decode-integer;

  export data,
    concrete-frame-fields,
    <repeated-field>, <malformed-packet-error>;

  export byte-aligned, high-level-type;

  export n-byte-vector-definer, n-bit-unsigned-integer-definer;

  export hexdump;

  export <unsigned-byte>,
    <3byte-big-endian-unsigned-integer>,
    <2byte-big-endian-unsigned-integer>, <2byte-little-endian-unsigned-integer>,
    <3byte-little-endian-unsigned-integer>,
    <1bit-unsigned-integer>, <2bit-unsigned-integer>, <3bit-unsigned-integer>,
    <4bit-unsigned-integer>, <5bit-unsigned-integer>, <6bit-unsigned-integer>,
    <7bit-unsigned-integer>, <9bit-unsigned-integer>, <10bit-unsigned-integer>,
    <11bit-unsigned-integer>, <12bit-unsigned-integer>, <13bit-unsigned-integer>,
    <14bit-unsigned-integer>, <15bit-unsigned-integer>, <20bit-unsigned-integer>;

  export <variable-size-byte-vector>, <externally-delimited-string>,
    <raw-frame>;
  
  export $empty-externally-delimited-string, $empty-raw-frame;

  //XXX: evil hacks
  export float-to-byte-vector-le, byte-vector-to-float-le,
    float-to-byte-vector-be, byte-vector-to-float-be,
    <big-endian-unsigned-integer-4byte>, big-endian-unsigned-integer-4byte,
    <little-endian-unsigned-integer-4byte>, little-endian-unsigned-integer-4byte,;


  export <fixed-size-translated-leaf-frame>, <byte-sequence>,
    <fixed-size-byte-vector-frame>;

  export <integer-or-unknown>, $unknown-at-compile-time;

  export <malformed-packet-error>, <parse-error>;

  export <frame-field>,
    <repeated-frame-field>,
    <rep-frame-field>,
    <position-mixin>,
    parent-frame-field,
    frame-field-list,
    start-offset,
    length,
    end-offset,
    frame,
    field,
    value;

  export <field>,
    static-start,
    static-length,
    static-end,
    field-name,
    field-size,
    getter,
    setter,
    fixup-function,
    type;

  export <frame>,
    <leaf-frame>,
    parse-frame,
    assemble-frame,
    assemble-frame-into,
    assemble-frame!,
    copy-frame,
    assemble-frame-as,
    read-frame,
    summary;

  export sorted-frame-fields,
    get-frame-field,
    fields,
    find-protocol,
    find-protocol-field;

  export <container-frame>,
    <unparsed-container-frame>,
    <decoded-container-frame>,
    fields-initializer,
    frame-name,
    unparsed-class,
    decoded-class,
    field-count,
    fixup!,
    parent,
    packet,
    cache,
    source-address, source-address-setter,
    destination-address, destination-address-setter,
    payload-type,
    container-frame-size,
    layer-magic,
    lookup-layer, reverse-lookup-layer;

  export <header-frame>,
    <unparsed-header-frame>,
    <decoded-header-frame>,
    payload, payload-setter;

  export <inline-layering-error>,
    <missing-inline-layering-error>,
    <variably-typed-container-frame>,
    <unparsed-variably-typed-container-frame>,
    <decoded-variably-typed-container-frame>;

  export frame-size,
    byte-offset,
    bit-offset;

  export protocol-definer;
  //XXX: we shouldn't need to export those
  export real-class-definer, decoded-class-definer, gen-classes,
    frame-field-generator, summary-generator, enum-frame-field-generator,
    unparsed-frame-field-generator;

  export protocol-module-definer;
end module packetizer;

define module packet-filter
  use common-dylan, exclude: { format-to-string };
  use format;
  use format-out;
  use print;
  use simple-parser;
  use source-location;
  use source-location-rangemap;
  use grammar;
  use simple-lexical-scanner;
  use packetizer;

  export 
    <filter-expression>,
    <field-equals>,
    <and-expression>,
    <or-expression>,
    <not-expression>,
    matches?,
    parse-filter,
    build-frame-filter;
end;


