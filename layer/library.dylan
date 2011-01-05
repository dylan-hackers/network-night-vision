Module:    dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

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
