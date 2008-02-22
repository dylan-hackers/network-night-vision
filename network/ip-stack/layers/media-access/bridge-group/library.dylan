module: dylan-user

define library bridge-group
  use common-dylan;
  use layer;
  use packetizer;
  use protocols;
  use flow;
  use network-flow;
end;

define module bridge-group
  use common-dylan;
  use new-layer;
  use ethernet;
  use packetizer;
  use flow;
  use network-flow;
  use socket;
end;
