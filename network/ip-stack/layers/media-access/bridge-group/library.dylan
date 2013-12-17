module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library bridge-group
  use common-dylan;
  use layer;
  use binary-data;
  use protocols;
  use flow;
  use network-flow;
end;

define module bridge-group
  use common-dylan;
  use new-layer;
  use ethernet;
  use binary-data;
  use flow;
  use network-flow;
  use socket;
end;
