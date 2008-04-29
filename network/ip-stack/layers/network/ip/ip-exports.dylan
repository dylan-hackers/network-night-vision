module: dylan-user

define library ip
  use common-dylan;
  use io;
  use layer;
  use packetizer;
  use protocols;
  use flow;
  use network-flow;
  use ip-adapter;
end library;

define module ip
  use common-dylan;
  use format-out;
  use new-layer;
  use ipv4;
  use packetizer;
  use flow;
  use network-flow;
  use socket;
  use cidr;
  use ip-adapter;
  use format;
end module;
