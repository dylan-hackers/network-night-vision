module: dylan-user

define library web-sniffer
  use common-dylan;
  use io;
  use system;

  //web stuff
  use http-common;
  use http-server;
  use json;

  //nnv stuff
  use binary-data;
  use network-interfaces;
  use protocols;
  use layer;
  use flow;
  use network-flow;

  use packet-filter;
end;

define module web-sniffer
  use common-dylan, exclude: { format-to-string };
  use date;
  use format;
  use format-out;
  use standard-io;
  use streams;
  use threads;
  use print;


  //web stuff
  use http-common;
  use http-server;
  use json;

  //nnv stuff
  use binary-data;
  use network-interfaces;
  use ethernet;
  use layer;
  use flow;
  use network-flow;

  use packet-filter;
end module;

