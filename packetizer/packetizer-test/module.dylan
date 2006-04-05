Module:    dylan-user
Synopsis:  Test library for packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define module packetizer-test
  use common-dylan;
  use packetizer, exclude: { type-code, data };
  use testworks;
end module packetizer-test;
