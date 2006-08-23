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
  export <ethernet-frame>, <ipv4-frame>,
    <ipv4-address>, <mac-address>, <ieee80211-frame>, <prism2-frame>,
    <logical-link-control>, <link-control>,
    <ieee80211-information-field>,
    <ieee80211-data-frame>,
    <ieee80211-management-frame>,
    <ieee80211-control-frame>,
    operation, source-address, destination-address,
    type-code, <arp-frame>, target-mac-address,
    target-ip-address, source-ip-address, source-mac-address,
    mac-address, ipv4-address, 
    <decoded-arp-frame>, <decoded-ethernet-frame>,
    <fixed-size-byte-vector-frame>, data,
    total-length, concrete-frame-fields,
    <repeated-field>, <malformed-packet-error>;

  export <pcap-file>, <pcap-file-header>, <pcap-packet>, header, packets,
    $DLT-EN10MB, $DLT-PRISM-HEADER, make-unix-time, decode-unix-time, timestamp;

  export <icmp-frame>, code, type, checksum;

  export <raw-frame>;

  export $broken-ipv4, hexdump;

  export <unsigned-byte>, <3byte-big-endian-unsigned-integer>,
    <3byte-little-endian-unsigned-integer>,
    <externally-delimited-string>;

  export <integer-or-unknown>, $unknown-at-compile-time;

  export <malformed-packet-error>;

  export <frame-field>,
    <repeated-frame-field>,
    <rep-frame-field>,
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
    read-frame,
    summary;

  export sorted-frame-fields,
    get-frame-field,
    fields,
    find-protocol,
    find-protocol-field;

  export <container-frame>,
    <container-frame-cache>,
    <unparsed-container-frame>,
    <decoded-container-frame>,
    frame-name,
    unparsed-class,
    decoded-class,
    cache-class,
    field-count,
    fixup!,
    parent,
    packet;

  export <header-frame>,
    <header-frame-cache>,
    <unparsed-header-frame>,
    <decoded-header-frame>,
    payload;

  export frame-size,
    byte-offset,
    bit-offset;

  export protocol-definer;
  //XXX: we shouldn't need to export those
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


