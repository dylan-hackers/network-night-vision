Module:    dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library packetizer
  use common-dylan;
  use dylan;
  use io;
  use collections;
  use collection-extensions;
  use system;

  use source-location;
  use grammar;
  use simple-parser;
  use regular;

  // Add any more module exports here.
  export packetizer, packet-filter;
end library packetizer;
