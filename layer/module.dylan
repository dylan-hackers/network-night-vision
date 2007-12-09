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
  use packet-filter;
  use timer;
  use flow;
  use network-interfaces;
  use vector-table;
  use byte-vector;
  use date, import: {<date>, current-date };
  use tcp-state-machine;
  use state-machine, export: { process-event };
  use simple-random;
  use streams;
  use ipv4;
  use dhcp;
  use dhcp-state-machine;
  use tcp;
  use icmp;
  use ethernet;
  use dns, exclude: { ipv4-address };
  use cidr;
  use print;
  // Add binding exports here.

  export <ethernet-layer>,
    ethernet-interface,
    <ip-over-ethernet-adapter>,
    arp-handler,
    print-arp-table,
    <ip-layer>,
    print-forwarding-table,
    <icmp-handler>,
    <icmp-over-ip-adapter>,
    <arp-handler>,
    register-route,
    init-arp-handler,
    decapsulator,
    create-socket,
    create-filter-socket,
    create-raw-socket,
    close-socket,
    build-ethernet-layer,
    build-ip-layer,
    send-socket,
    send,
    set-ip-address,
    delete-route,
    add-next-hop-route;

  export <udp-layer>, build-udp-layer,
    <tcp-layer>;

  export <dhcp-client>, find-option;
end module layer;
