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
    <out-of-bound-error>,
    encode-integer;

  export <udp-frame>, source-port, destination-port, length, checksum;

  export <tcp-frame>, sequence-number, acknowledgement-number,
    urg, ack, psh, rst, syn, fin, window, urgent-pointer, options-and-padding;

  export <ethernet-frame>, <ipv4-frame>,
    <ipv4-address>, <mac-address>, <ieee80211-frame>, <prism2-frame>,
    <logical-link-control>, <link-control>,
    <ieee80211-information-field>,
    <ieee80211-data-frame>,
    <ieee80211-management-frame>,
    <ieee80211-control-frame>,
    operation, type-code, <arp-frame>, target-mac-address,
    target-ip-address, source-ip-address, source-mac-address,
    mac-address, ipv4-address, 
    <decoded-arp-frame>, <decoded-ethernet-frame>,
    <fixed-size-byte-vector-frame>, data,
    total-length, concrete-frame-fields,
    <repeated-field>, <malformed-packet-error>;

  export byte-aligned, high-level-type;

  export <pcap-file>, <pcap-file-header>, <pcap-packet>, header, packets,
    $DLT-EN10MB, $DLT-PRISM-HEADER, make-unix-time, decode-unix-time, timestamp;

  //XXX: evil hacks
  export float-to-byte-vector-le, byte-vector-to-float-le,
    float-to-byte-vector-be, byte-vector-to-float-be,
    big-endian-unsigned-integer-4byte;

  export <icmp-frame>, code, type, checksum;

  export <raw-frame>;

  export hexdump;

  export <unsigned-byte>,
    <3byte-big-endian-unsigned-integer>,
    <2byte-big-endian-unsigned-integer>,
    <3byte-little-endian-unsigned-integer>,
    <externally-delimited-string>, <1bit-unsigned-integer>,
    <4bit-unsigned-integer>, <7bit-unsigned-integer>;

  export <fixed-size-translated-leaf-frame>, <byte-sequence>;

  export <integer-or-unknown>, $unknown-at-compile-time;

  export <malformed-packet-error>;

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
    source-address,
    destination-address,
    payload-type,
    get-protocol-magic;

  export <header-frame>,
    <unparsed-header-frame>,
    <decoded-header-frame>,
    payload;

  export frame-size,
    byte-offset,
    bit-offset;

  export protocol-definer;
  //XXX: we shouldn't need to export those
  export real-class-definer, decoded-class-definer, gen-classes,
    frame-field-generator, summary-generator, unparsed-frame-field-generator; 
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
    parse-filter;
end;


