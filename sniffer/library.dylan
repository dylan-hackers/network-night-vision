module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define library sniffer
  use common-dylan;
  use io;
  use command-line-parser;
  use flow;
  use network-flow;
  use system;
  use network-interfaces;
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
  use network-interfaces;
end;
