module: dylan-user
Author: Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define library id3v2-test
  use common-dylan;
  use io;
  use parse-arguments;
  use flow;
  use network-flow;
  use system;
  use interfaces;
  use id3v2;
end;

define module id3v2-test
  use common-dylan;
  use streams;
  use format-out;
  use standard-io;
  use file-system;
  use flow;
  use network-flow;
  use parse-arguments;
  use interfaces;
  use id3v2;
end;
