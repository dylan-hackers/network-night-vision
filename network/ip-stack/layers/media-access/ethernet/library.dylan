module: dylan-user

define library ethernet
  use common-dylan;
  use layer;
  use packetizer;
  use protocols, rename: { ethernet => ethernet-frame };
  use flow;
  use network-flow;
end;

define module ethernet
  use common-dylan;
  use new-layer;
  use ethernet-frame;
  use packetizer;
  use flow;
  use network-flow;
  use socket;
end;
