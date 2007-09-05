Module:    dylan-user
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define library gui-sniffer
  use dylan;
  use common-dylan;
  use duim;
  //use win32-duim;
  use deuce;
  use duim-deuce;
  use io;
  use system;
  use packetizer;
  use flow;
  use network-flow;
  use protocols;
  use interfaces;
  use layer;
end library gui-sniffer;
