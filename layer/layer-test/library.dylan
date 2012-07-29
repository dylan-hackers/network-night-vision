Module:    dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library layer-test
  use dylan;
  use io;
  use common-dylan;
  use testworks;
  use layer;

  export layer-test;
end library layer-test;

define module layer-test
  use dylan;
  use format;
  use format-out;
  use standard-io;
  use streams;
  use new-layer;
  use testworks;
end module layer-test;
