Module:    dylan-user
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define library icmp-responder
  use functional-dylan;
  use io;
  use network-flow;
  use flow;
  use packetizer;
  use interfaces;

  // Add any more module exports here.
  export icmp-responder;
end library icmp-responder;
