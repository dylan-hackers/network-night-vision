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

  // Add any more module exports here.
  export layer;
end library layer;
