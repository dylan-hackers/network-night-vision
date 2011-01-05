module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define library ethernet
  use common-dylan;
  use layer;
  use packetizer;
  use protocols, rename: { ethernet => ethernet-frame };
  use flow;
  use network-flow;

  export ethernet;
end;

define module ethernet
  use common-dylan;
  use new-layer;
  use ethernet-frame;
  use packetizer;
  use flow;
  use network-flow;
  use socket;

  export @mac-address;
end;
