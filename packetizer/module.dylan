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
    <frame-field>, <repeated-field>, field, name,
    <pcap-file>, <pcap-file-header>, <pcap-packet>, packets;

  export <icmp-frame>, code, type, checksum;

  export <raw-frame>;

  export fixup!;

  export $broken-ipv4, hexdump;

  export frame-fields, getter;
end module packetizer;

define module packet-filter
  use common-dylan;
  use format-out;
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
