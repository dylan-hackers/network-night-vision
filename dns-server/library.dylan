module: dylan-user

define library dns-server
  use common-dylan;
  use io;
  use packetizer;
  use protocols;
  use flow;
  use network-flow;
  use socket-flow;
end library;

define module dns-server
  use common-dylan;
  use format-out;
  use packetizer;
  use dns;
  use ipv4;
  use flow;
  use network-flow;
  use socket-flow;
  use streams, import: { force-output };
  use standard-io, import: { *standard-output* };
end module;
