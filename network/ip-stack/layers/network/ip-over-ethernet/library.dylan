module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library ip-over-ethernet
  use common-dylan;
  use io;
  use layer;
  use binary-data;
  use protocols;
  use flow;
  use network-flow;
  use ip-adapter;
  use arp;
  use ethernet, prefix: "layer-";
end library;

define module ip-over-ethernet
  use common-dylan;
  use format-out;
  use new-layer;
  use ipv4;
  use cidr;
  use binary-data;
  use flow;
  use network-flow;
  use socket;
  use ip-adapter;
  use ethernet;
  use layer-ethernet;
  use arp;
end module;
