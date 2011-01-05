Module:    dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define library gui-sniffer
  use dylan;
  use common-dylan;
  use duim;
  //use win32-duim;
  use deuce;
  use duim-deuce;
  use io;
  use system;
  use commands;
  use environment-commands;
  use packetizer;
  use flow;
  use network-flow;
  use protocols;
  use network-interfaces;
  use layer;
  use timer;
  use pcap-live-interface;
  use bridge-group;
  use ieee802-1q;
  use ethernet, rename: { ethernet => ethernet-layer };
  use ppp-over-ethernet;
  use arp;
  use ip;
  use ip-over-ethernet;
  use flow-printer;
end library gui-sniffer;
