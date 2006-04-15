module: dylan-user

define library pcap-wrapper
  use common-dylan;
  use c-ffi;
  use io;
  use collection-extensions;
  use functional-dylan;
  use flow;
  use network-flow;
  use packetizer;

  export pcap-wrapper;
end;

define module pcap-wrapper
  use common-dylan;
  use c-ffi;
  use format-out;
  use standard-io;
  use subseq;
  use dylan-direct-c-ffi;
  use machine-words;
  use byte-vector;
  use flow;
  use network-flow, import: { <verbose-printer>, <summary-printer>, <fan-out> };
  use packetizer, import: { unparsed-class, <ethernet-frame>, <frame>, assemble-frame };
  export <pcap-interface>;
end;

