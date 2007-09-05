Module:    dylan-user
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define module hex-view
  use common-dylan, exclude: { format-to-string };
  use streams;
  use format;
  use format-out;
  use deuce;
  use deuce-internals;

  export show-hexdump, set-highlight, hexdump;
end;

define module gui-sniffer
  use common-dylan, exclude: { format-to-string };
  use dylan-extensions, import: { debug-name };
  use threads;
  use duim, exclude: { <frame>, frame-size };
//  use win32-duim;
  use deuce;
  use duim-deuce;
  use format;
  use format-out;
  use streams;
  use date;
  use file-system;
  use operating-system;
  use packetizer, exclude: { hexdump };
  use packet-filter;
  use network-flow;
  use flow;
  use hex-view;
  use ethernet, import: { <ethernet-frame> };
  use pcap, import: { make-unix-time, <pcap-packet>, decode-unix-time, timestamp };
  use prism2, import: { <prism2-frame> };
  use ipv4, import: { <ipv4-frame>, <udp-frame>, source-port, destination-port, acknowledgement-number, sequence-number };
  use icmp, import: { <icmp-frame> };
  use tcp;
  use ipv6;
  // Add binding exports here.
  use deuce-internals, prefix: "deuce/";
  use interfaces;
  use layer;
end module gui-sniffer;
