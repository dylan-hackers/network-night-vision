module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define library pcap-live-interface
  use common-dylan;
  use layer;
  use physical-layer;
  use c-ffi;
  use system;
  use io;
  use collection-extensions;
  use functional-dylan;
  use flow;
  use network-flow;
  use network;
  use packetizer;
  use protocols, import: { ethernet, ipv4, cidr };
end;

define module pcap-live-interface
  use common-dylan;
  use new-layer;
  use socket;
  use c-ffi;
  use winsock2, import: { <timeval>, <lpsockaddr>, <C-buffer-offset> };
  use physical-layer;
  //use format-out;
  use standard-io;
  use subseq;
  use dylan-direct-c-ffi;
  use machine-words;
  use byte-vector;
  use flow;
  use network-flow;
  use print;
  use format;
  use threads;
  use ethernet, import: { <ethernet-frame> };
  use ipv4, import: { <ipv4-address> };
  use cidr, import: { <cidr>, netmask-from-byte-vector };
  use packetizer,
    import: { parse-frame,
              <frame>,
              assemble-frame!,
              packet,
              <stretchy-vector-subsequence> };
end;
