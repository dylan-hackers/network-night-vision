module: dylan-user

define library socket-flow
  use dylan;
  use common-dylan;
  use io;
  use packetizer;
  use network;
  use network-flow;
  use flow;
  use c-ffi;
  use protocols;

  export socket-flow;
end library;

define module socket-flow
  use common-dylan, exclude: { close };
  use format-out;
  use packetizer;
  use WinSock2, exclude: { connect };
  use network-flow;
  use flow;
  use c-ffi;
  use ipv4;
  use sockets, import: { start-sockets };
  //use sockets, import: { interruptible-system-call };
  use dylan-direct-c-ffi;
  use streams, import: { force-output };
  use standard-io, import: { *standard-output* };

  export <flow-socket>, sendto-socket;
end module;
