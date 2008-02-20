module: dylan-user

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
  use network;
  use packetizer;
  use protocols, import: { ethernet, ipv4, cidr };
end;

define module pcap-live-interface
  use common-dylan;
  use new-layer;
  use c-ffi;
  use winsock2;
  use physical-layer;
  //use format-out;
  use standard-io;
  use subseq;
  use dylan-direct-c-ffi;
  use machine-words;
  use byte-vector;
  use flow;
  use print;
  use format;
  use threads;
  use ethernet, import: { <ethernet-frame> };
  use ipv4, import: { <ipv4-address> };
  use cidr, import: { <cidr>, netmask-from-byte-vector };
  use packetizer,
    import: { parse-frame,
              <frame>,
              assemble-frame,
              packet,
              <stretchy-vector-subsequence> };
end;
