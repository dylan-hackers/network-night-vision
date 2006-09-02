Module:    dylan-user
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define module gui-sniffer
  use common-dylan, exclude: { format-to-string };
  use threads;
  use duim, exclude: { <frame>, frame-size };
  use win32-duim;
  use format;
  use format-out;
  use standard-io;
  use streams;
  use date;
  use file-system;
  use operating-system;
  use packetizer;
  use packet-filter;
  use network-flow;
  use flow;
  use interfaces;
  // Add binding exports here.

end module gui-sniffer;
