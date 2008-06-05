module: dylan-user


define library arp
  use common-dylan;
  use io;
  use system;
  use layer;
  use packetizer;
  use protocols, rename: { ethernet => protocols-ethernet };
  use flow;
  use network-flow;
  use timer;
  use vector-table;
  use ethernet;

  export arp;
end library;

define module arp
  use common-dylan;
  use threads;
  use vector-table;
  use format-out;
  use new-layer;
  use ipv4;
  use cidr;
  use packetizer;
  use flow;
  use network-flow;
  use socket;
  use ethernet;
  use date;
  use format;
  use timer;
  use print;
  use protocols-ethernet;

  export arp-resolve, $broadcast-ethernet-address, print-arp-table,
    add-advertised-arp-entry, remove-arp-entry;
end module;
