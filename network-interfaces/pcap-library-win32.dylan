module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library network-interfaces
  use common-dylan;
  use c-ffi;
  use io;
  use dylan;
  use flow;
  use network;
  use binary-data;

  use protocols, import: { ethernet, ipv4, cidr };

  export network-interfaces;
end;

define module network-interfaces
  use common-dylan;
  use c-ffi;
  use winsock2, import: { sa-data-array, <timeval>,
                          <lpsockaddr>, <C-buffer-offset> };
  //use format-out;
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
  use binary-data,
    import: { parse-frame,
              <frame>,
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

