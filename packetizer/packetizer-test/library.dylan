Module:    dylan-user
Synopsis:  Test library for packetizer
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library packetizer-test
  use common-dylan;
  use testworks;
  use packetizer;
end library packetizer-test;

define module packetizer-test
  use common-dylan;
  use packetizer, exclude: { type-code, data };
  use testworks;
end module packetizer-test;
