Module:    dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

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
  use bittorrent;
  use dhcp;
  use dhcp-state-machine;
  use ppp-state-machine;
  use pppoe;
  use ppp;
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

  export <pppoe-client>;
end module layer;

define module new-layer
  use common-dylan;
  use format;
  use print;
  use regular-expressions;
  use streams;

  export <layer>, layer-name, default-name,
    lower-layers, upper-layers,
    sockets, sockets-setter,
    initialize-layer,
    connect-layer, disconnect-layer,
    register-lower-layer, register-upper-layer,
    deregister-lower-layer, deregister-upper-layer,
    check-lower-layer?, check-upper-layer?;

  export @running-state, @running-state-setter,
    @administrative-state, @administrative-state-setter;

  export <event>, <event-source>,
    event-notify, register-event, deregister-event,
    register-property-changed-event, deregister-property-changed-event;

  export find-layer, find-layer-type, find-all-layers,
    print-layer, print-config, read-config;

  export create-raw-socket,
    start-layer, register-startup-function;

  export <property>, property-name,
    property-type, property-default-value,
    property-value, property-value-setter,
    property-owner, read-into-property,
    read-as, property-set?, $unset;

  export get-property, get-properties,
    set-property-value, get-property-value,
    check-property, print-property;

  export <property-changed-event>,
    property-changed-event-property,
    property-changed-event-old-value;

  export \layer-definer,
    \add-properties-to-table,
    \layer-getter-and-setter-definer;
end;

define module socket
  use common-dylan;
  use format;
  use network-flow;
  use flow;
  use new-layer;

  export <socket>, <flow-node-socket>,
    create-socket, flow-node, socket-owner,
    check-socket-arguments?;

  export <input-output-socket>, socket-input, socket-output;

  export send, close-socket, sendto;

  export <tapping-socket>, create-tapping-socket;
end;

