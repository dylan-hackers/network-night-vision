module: dylan-user

define library ip-adapter
  use common-dylan;
  use io;
  use layer;
  use packetizer;
  use protocols;
  use flow;
  use network-flow;

  export ip-adapter;
end library;

define module ip-adapter
  use common-dylan;
  use format-out;
  use new-layer;
  use ipv4;
  use cidr;
  use packetizer;
  use flow;
  use network-flow;
  use socket;

  export <ip-adapter-layer>,
    @ip-address, @ip-address-setter,
    @mtu, @mtu-setter,
    @running-state, @running-state-setter;
end module;
