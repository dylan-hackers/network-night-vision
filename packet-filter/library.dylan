Module:    dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library packet-filter
  use common-dylan;
  use dylan;
  use io;
  use collections;
  use system;

  use source-location;
  use grammar;
  use simple-parser;
  use regular;

  use packetizer;

  export packet-filter;
end library packet-filter;

define module packet-filter
  use common-dylan, exclude: { format-to-string };
  use format;
  use format-out;
  use print;
  use simple-parser;
  use source-location;
  use source-location-rangemap;
  use grammar;
  use simple-lexical-scanner;
  use packetizer;

  export 
    <filter-expression>,
    <field-equals>,
    <and-expression>,
    <or-expression>,
    <not-expression>,
    matches?,
    parse-filter,
    build-frame-filter;
end;
