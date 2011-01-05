module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

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
    @mtu, @mtu-setter;
end module;
