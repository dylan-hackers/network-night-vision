module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define library pcap-live-interface
  use common-dylan;
  use layer;
  use physical-layer;
  use c-ffi;
  use network;
  use system;
  use io;
  use collection-extensions;
  use functional-dylan;
  use flow;
  use network-flow;
  use network;
  use packetizer;
  use protocols, import: { ethernet, prism2, ieee80211 };
end;

define module pcap-live-interface
  use common-dylan, exclude: { format-to-string, close };
  use new-layer;
  use socket;
  use physical-layer;
  use dylan-extensions;
  use threads;
  use common-extensions, exclude: { format-to-string, close };
  use format-out, exclude: { close };
  use subseq;
  use format;
  use standard-io;
  use functional-dylan, import: { <byte-character> };
  use dylan-extensions, import: { <byte> };
  use unix-sockets, exclude: { send, connect };
  use sockets, import: { interruptible-system-call };
  use C-FFI;
  use dylan-direct-c-ffi;
  use flow;
  use network-flow;
  use packetizer, import: { parse-frame, assemble-frame, packet };
  use ethernet, import: { <ethernet-frame> };
  use ieee80211, import: { <ieee80211-frame> };
  use prism2, import: { <prism2-frame>, <bsd-80211-radio-frame> };

end;
