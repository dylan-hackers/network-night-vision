module: dylan-user

define library ppp-over-ethernet
  use common-dylan;
  use layer;
  use packetizer;
  use protocols;
  use flow;
  use network-flow;
  use ppp-state-machine;
  use state-machine;
end;

define module ppp-over-ethernet
  use common-dylan;
  use new-layer;
  use pppoe, rename: { session-id => pppoe-session-id };
  use packetizer;
  use ethernet, import: { mac-address };
  use flow;
  use network-flow;
  use socket;
  use ppp-state-machine;
  use simple-random;
  use state-machine;
end;
