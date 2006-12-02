Module:    dylan-user
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define module network-flow
  use common-dylan, exclude: { format-to-string };
  use threads;
  use format;
  use streams;
  use standard-io;
  use flow;
  use packetizer;
  use packet-filter;
  use file-system;
  use pcap, import: { packets, <pcap-file-header>, <pcap-packet>, <pcap-file> };

  export <summary-printer>, <verbose-printer>,
    <decapsulator>, <encapsulator>,
    <demultiplexer>, create-output-for-filter,
    <completer>,
    <frame-filter>,
    <pcap-file-reader>,
    <pcap-file-writer>,
    <malformed-packet-writer>,
    <fan-out>, <fan-in>;
end module network-flow;
