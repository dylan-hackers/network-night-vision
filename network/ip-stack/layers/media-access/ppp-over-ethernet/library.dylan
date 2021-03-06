module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library ppp-over-ethernet
  use common-dylan;
  use layer;
  use binary-data;
  use protocols;
  use flow;
  use network-flow;
  use ppp-state-machine;
  use state-machine;
end;

define module ppp-over-ethernet
  use common-dylan;
  use new-layer;
  use pppoe, rename: { session-id => pppoe-session-id };
  use binary-data;
  use ethernet, import: { mac-address };
  use flow;
  use network-flow;
  use socket;
  use ppp-state-machine;
  use simple-random;
  use state-machine;
end;
