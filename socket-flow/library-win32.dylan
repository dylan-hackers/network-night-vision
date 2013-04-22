module: dylan-user

define library socket-flow
  use dylan;
  use common-dylan;
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
  use packetizer;
  use WinSock2, exclude: { connect };
  use network-flow;
  use flow;
  use c-ffi;
  use ipv4;
  use sockets, import: { start-sockets };
  use dylan-direct-c-ffi;

  export <flow-socket>;
end module;
