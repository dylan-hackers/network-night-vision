module:         packetizer
Author:         Andreas Bogk, Hannes Mehnert, mb
Copyright:      (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define protocol prism2-header-item (container-frame)
  field item-did :: <little-endian-unsigned-integer-4byte>;
  field item-status :: <2byte-little-endian-unsigned-integer>;
  field item-length :: <2byte-little-endian-unsigned-integer>;
  field item-data :: <little-endian-unsigned-integer-4byte>;
end;

define protocol prism2-frame (header-frame)
  summary "PRISM2/%s", compose(summary, payload);
  field message-code :: <little-endian-unsigned-integer-4byte>;
  field messsage-len :: <little-endian-unsigned-integer-4byte>;
  field device-name :: <wlan-device-name>;
  field host-time :: <prism2-header-item>;
  field mac-time :: <prism2-header-item>;
  field channel :: <prism2-header-item>;
  field rssi :: <prism2-header-item>;
  field sq ::  <prism2-header-item>;
  field signal-level ::  <prism2-header-item>;
  field noise-level ::  <prism2-header-item>;
  field rate ::  <prism2-header-item>;
  field istx ::  <prism2-header-item>;
  field frame-length ::  <prism2-header-item>;
  field payload :: <ieee80211-frame>;
end;
