module: dylan-user
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define library sniffer
  use common-dylan;
  use io;
  use parse-arguments;
  use flow;
  use network-flow;
  use system;
end;

define module sniffer
  use common-dylan;
  use streams;
  use format;
  use standard-io;
  use file-system;
  use flow;
  use network-flow;
  use parse-arguments;
end;
