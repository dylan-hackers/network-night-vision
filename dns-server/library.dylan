module: dylan-user

define library dns-server
  use common-dylan;
  use io;
  use binary-data;
  use protocols;
  use flow;
  use network-flow;
  use socket-flow;
  use system;
  use command-line-parser;
end library;

define module dns-server
  use common-dylan, exclude: { format-to-string };
  use format-out;
  use print;
  use streams;
  use format;
  use file-system;
  use binary-data;
  use dns;
  use ipv4;
  use flow;
  use network-flow;
  use socket-flow;
  use streams, import: { force-output };
  use standard-io, import: { *standard-output* };
  use command-line-parser;
  use simple-random;
end module;
