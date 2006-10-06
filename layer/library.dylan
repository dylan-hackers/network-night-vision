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
  use interfaces;
  use vector-table;
  use system, import: { date };
  use tcp;

  // Add any more module exports here.
  export layer;
end library layer;
