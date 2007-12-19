Module:    dylan-user
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define library network-interfaces
  use common-dylan;
  use functional-dylan;
  use network;
  use C-FFI;
  use io;
  use collection-extensions;
  use flow;
  use packetizer;
  use protocols, import: { ethernet, prism2, ieee80211 };

  export network-interfaces;
end library network-interfaces;

define module network-interfaces
  use common-dylan, exclude: { format-to-string, close };
  use dylan-extensions;
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
  use packetizer, import: { parse-frame, assemble-frame, packet };
  use ethernet, import: { <ethernet-frame> };
  use ieee80211, import: { <ieee80211-frame> };
  use prism2, import: { <prism2-frame>, <bsd-80211-radio-frame> };

  export <ethernet-interface>, interface-name, find-all-devices, device-name,
    running?, running?-setter;
end module network-interfaces;
