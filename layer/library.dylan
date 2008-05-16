Module:    dylan-user
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define library layer
  use common-dylan;
  use io;
  use network-flow;
  use flow;
  use packetizer;
  use timer;
  use network-interfaces;
  use vector-table;
  use system, import: { date };
  use tcp-state-machine;
  use state-machine;
  use protocols;
  use dhcp-state-machine;
  use ppp-state-machine;
  use regular-expressions;

  // Add any more module exports here.
  export layer;
  export new-layer;
  export socket;
end library layer;
