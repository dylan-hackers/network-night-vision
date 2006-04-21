Module:    dylan-user
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define module icmp-responder
  use functional-dylan;
  use threads;
  use format;
  use format-out;
  use standard-io;
  use streams;
  use network-flow;
  use flow;
  use packetizer;
  use interfaces;

  // Add binding exports here.

end module icmp-responder;
