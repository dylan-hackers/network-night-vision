Module:    dylan-user
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define module packetizer
  use common-dylan, exclude: { format-to-string };
  use threads;
  use format;
  use format-out;
  use standard-io;
  use streams;
  use bit-vector;
  use print, import: { print-object };
  use byte-vector;
  use subseq;
  use file-system;
  use date;

  // Add binding exports here.
  export <frame>, <ethernet-frame>, <ipv4-frame>,
    <ipv4-address>, <mac-address>, payload,
    operation, source-address, destination-address,
    type-code, <arp-frame>,
    target-ip-address, source-ip-address, source-mac-address,
    assemble-frame,
    <decoded-arp-frame>, <decoded-ethernet-frame>,
    parse-frame, summary, unparsed-class,
    <fixed-size-byte-vector-frame>, data,
    total-length, concrete-frame-fields,
    <leaf-frame>, <container-frame>, frame, type,
    <header-frame>,
    <repeated-field>, field, name;

  export <frame-field>, start-offset, length, end-offset;

  export <field>, static-start, static-length, static-end,
    field-size;
  export <pcap-file>, <pcap-file-header>, <pcap-packet>, header, packets;

  export read-frame;

  export <icmp-frame>, code, type, checksum;

  export <raw-frame>;

  export fixup!;

  export $broken-ipv4, hexdump;

  export sorted-frame-fields, get-frame-field,
    fields, getter, find-protocol, find-protocol-field;

  export <unsigned-byte>;
  export <integer-or-unknown>, $unknown-at-compile-time;
  export <container-frame-cache>, <unparsed-container-frame>, <decoded-container-frame>;
  export protocol-definer;
  export real-class-definer, cache-class-definer, decoded-class-definer, gen-classes,
    frame-field-generator, summary-generator, unparsed-frame-field-generator; 
end module packetizer;

define module packet-filter
  use common-dylan;
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

define module packetizer-test
  use common-dylan;
  use testworks;
  use packetizer;
end;


