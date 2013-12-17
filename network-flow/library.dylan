Module:    dylan-user
Synopsis:  A brief description of the project.
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library network-flow
  use common-dylan;
  use flow;
  use binary-data;
  use packet-filter;
  use io;
  use system;
  use protocols, import: { pcap };

  export network-flow;
end library network-flow;

define module network-flow
  use common-dylan, exclude: { format-to-string };
  use threads;
  use format;
  use streams;
  use standard-io;
  use flow;
  use binary-data;
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
    <fan-out>, <fan-in>,
    create-input, create-output;
end module network-flow;
