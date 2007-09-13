Module:    dylan-user
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define module layer
  use common-dylan;
  use standard-io;
  use format;
  use format-out;
  use threads;
  use network-flow;
  use packetizer;
  use timer;
  use flow;
  use network-interfaces;
  use vector-table;
  use byte-vector;
  use date, import: {<date>, current-date };
  use tcp-state-machine;
  use simple-random;
  use streams;
  use ipv4;
  use tcp;
  use icmp;
  use ethernet;
  use dns, exclude: { ipv4-address };
  use cidr;
  // Add binding exports here.

  export <ethernet-layer>,
    ethernet-interface,
    <ip-over-ethernet-adapter>,
    <ip-layer>,
    <icmp-handler>,
    <icmp-over-ip-adapter>,
    <arp-handler>,
    register-route,
    init-arp-handler,
    decapsulator,
    create-socket,
    create-raw-socket,
    build-ethernet-layer,
    build-ip-layer,
    send-socket,
    send;

  export <udp-layer>,
    <tcp-layer>;
end module layer;
