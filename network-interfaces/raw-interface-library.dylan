Module:    dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library network-interfaces
  use common-dylan;
  use dylan;
  use network;
  use C-FFI;
  use io;
  use flow;
  use binary-data;
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
  use dylan-extensions, import: { <byte>, <byte-character> };
  use unix-sockets, exclude: { send, connect };
  use sockets, import: { interruptible-system-call };
  use C-FFI;
  use dylan-direct-c-ffi;
  use flow;
  use binary-data, import: { parse-frame, assemble-frame, packet };
  use ethernet, import: { <ethernet-frame> };
  use ieee80211, import: { <ieee80211-frame> };
  use prism2, import: { <prism2-frame>, <bsd-80211-radio-frame> };

  export <ethernet-interface>, interface-name, find-all-devices, device-name,
    running?, running?-setter;
end module network-interfaces;
