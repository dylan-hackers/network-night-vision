module: dylan-user
Author: Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define library id3v2
  use common-dylan;
  use io;
  use command-line-parser;
  use flow;
  use network-flow;
  use system;
  use packetizer;

  export id3v2;
end;

define module id3v2
  use common-dylan;
  use streams;
  use format;
  use format-out;
  use standard-io;
  use file-system;
  use flow;
  use network-flow;
  use command-line-parser;
  use packetizer;
	
  export <id3v2-reader>, <id3v2-tag>;
end;
