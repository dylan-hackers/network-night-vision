module: dylan-user
author: Andreas Bogk, Hannes Mehnert
copyright: (c) 2006, All rights reserved. Free for non-commercial user

define library interfaces
  use common-dylan;
  use c-ffi;
  use io;
  use collection-extensions;
  use functional-dylan;
  use flow;
  use network;
  use packetizer;

  use protocols, import: { ethernet, ipv4, cidr };

  export interfaces;
end;

define module interfaces
  use common-dylan;
  use c-ffi;
  use winsock2;
  use format-out;
  use standard-io;
  use subseq;
  use dylan-direct-c-ffi;
  use machine-words;
  use byte-vector;
  use flow;
  use print;
  use format;
  use ethernet, import: { <ethernet-frame> };
  use ipv4, import: { <ipv4-address> };
  use cidr, import: { <cidr>, netmask-from-byte-vector };
  use packetizer,
    import: { parse-frame,
              <ethernet-frame>,
              assemble-frame,
              packet,
              <stretchy-vector-subsequence> };
  export <ethernet-interface>,
    interface-name,
    running?-setter,
    running?,
    find-all-devices;

  export <device>,
    device-name,
    device-cidrs;
end;

