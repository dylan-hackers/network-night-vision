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

define module command-line
  use common-dylan, exclude: { format-to-string };
  use streams;
  use format;
  use format-out;
  use deuce;
  use deuce-internals;
  use duim-deuce-internals;
  use threads;
  use commands;
  use command-lines;

  export make-nnv-shell-pane, command-line-server, nnv-context, nnv-context-setter, <nnv-context>;
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
  use standard-io;
  use streams;
  use date;
  use file-system;
  use operating-system;
  use packetizer, exclude: { hexdump };
  use packet-filter;
  use network-flow;
  use flow;
  use command-line;
  use commands;
  use command-lines;
  use hex-view;
  use ethernet, import: { <ethernet-frame> };
  use pcap, import: { make-unix-time, <pcap-packet>, decode-unix-time, timestamp };
  use prism2, import: { <prism2-frame> };
  use ipv4, import: { <ipv4-frame>, <udp-frame>, source-port, destination-port,
                      acknowledgement-number, sequence-number, ipv4-address, <ipv4-address> };
  use icmp, import: { <icmp-frame>, icmp-frame };
  use tcp;
  use ipv6;
  // Add binding exports here.
  use deuce-internals, prefix: "deuce/";
  use network-interfaces;
  use layer;
end module gui-sniffer;
