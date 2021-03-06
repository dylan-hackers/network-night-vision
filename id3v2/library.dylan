module: dylan-user
author: mb, Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 mb, Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library id3v2
  use common-dylan;
  use io;
  use command-line-parser;
  use flow;
  use network-flow;
  use system;
  use binary-data;

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
  use binary-data;
	
  export <id3v2-reader>, <id3v2-tag>;
end;
