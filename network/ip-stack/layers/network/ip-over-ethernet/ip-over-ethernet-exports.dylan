module: dylan-user

define library ip-over-ethernet
  use common-dylan;
  use io;
  use layer;
  use packetizer;
  use protocols;
  use flow;
  use network-flow;
  use ip-adapter;
  use arp;
end library;

define module ip-over-ethernet
  use common-dylan;
  use format-out;
  use new-layer;
  use ipv4;
  use cidr;
  use packetizer;
  use flow;
  use network-flow;
  use socket;
  use ip-adapter;
  use ethernet;
  use arp;
end module;
