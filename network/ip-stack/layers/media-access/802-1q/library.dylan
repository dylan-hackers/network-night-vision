module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define library ieee802-1q
  use common-dylan;
  use layer;
  use packetizer;
  use protocols;
  use flow;
  use network-flow;
end;

define module ieee802-1q
  use common-dylan;
  use new-layer;
  use ethernet;
  use packetizer;
  use flow;
  use network-flow;
  use socket;
end;
