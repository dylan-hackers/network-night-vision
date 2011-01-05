module:         prism2
author: mb, Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 mb, Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define protocol prism2-header-item (container-frame)
  field item-did :: <little-endian-unsigned-integer-4byte>;
  field item-status :: <2byte-little-endian-unsigned-integer>;
  field item-length :: <2byte-little-endian-unsigned-integer>;
  field item-data :: <little-endian-unsigned-integer-4byte>;
end;

define protocol prism2-frame (header-frame)
  field message-code :: <little-endian-unsigned-integer-4byte>;
  field message-len :: <little-endian-unsigned-integer-4byte>;
  field device-name :: <externally-delimited-string>
    = $empty-externally-delimited-string,
    static-length: 16 * 8;
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
  variably-typed-field payload,
    type-function: <ieee80211-frame>;
end;

define protocol bsd-80211-radio-frame (header-frame)
  field version :: <unsigned-byte>;
  field pad :: <unsigned-byte>;
  field frame-length :: <2byte-little-endian-unsigned-integer>;
  field it-present :: <little-endian-unsigned-integer-4byte>;
  field options :: <raw-frame>;
  variably-typed-field payload,
    type-function: <ieee80211-frame>,
    start: frame.frame-length * 8;
end;

