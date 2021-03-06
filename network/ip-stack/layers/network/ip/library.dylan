module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library ip
  use common-dylan;
  use io;
  use layer;
  use binary-data;
  use protocols;
  use flow;
  use network-flow;
  use ip-adapter;

  export ip;
end library;

define module ip
  use common-dylan, exclude: { format-to-string };
  use format-out;
  use new-layer;
  use print;
  use ipv4;
  use binary-data;
  use flow;
  use network-flow;
  use socket;
  use cidr;
  use ip-adapter;
  use format;

  export print-forwarding-table, add-next-hop-route, delete-route;
end module;
