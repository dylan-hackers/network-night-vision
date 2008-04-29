Module:    dylan-user
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

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
end library gui-sniffer;
