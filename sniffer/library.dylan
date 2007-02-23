module: dylan-user
Author: Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define library sniffer
  use common-dylan;
  use io;
  use command-line-parser;
  use flow;
  use network-flow;
  use system;
  use interfaces;
end;

define module sniffer
  use common-dylan;
  use streams;
  use format;
  use standard-io;
  use file-system;
  use flow;
  use network-flow;
  use command-line-parser;
  use interfaces;
end;
