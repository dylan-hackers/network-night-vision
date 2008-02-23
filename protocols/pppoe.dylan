module: pppoe
Author: Hannes Mehnert
Copyright: (C) 2008,  All rights reserved. Free for non-commercial use.

define protocol pppoe-session (header-frame)
  over <ethernet-frame> #x8864;
  field pppoe-version :: <4bit-unsigned-integer> = 1;
  field pppoe-type :: <4bit-unsigned-integer> = 1;
  field pppoe-code :: <unsigned-byte> = 0;
  field session-id :: <2byte-big-endian-unsigned-integer> = 0;
  field pppoe-length :: <2byte-big-endian-unsigned-integer>,
    fixup: byte-offset(frame-size(frame.payload));
  field payload :: <ppp>;
end;

define protocol pppoe-discovery (container-frame)
  over <ethernet-frame> #x8863;
  summary "PPPoE (session %=) %=", session-id, pppoe-code;
  field pppoe-version :: <4bit-unsigned-integer> = 1;
  field pppoe-type :: <4bit-unsigned-integer> = 1;
  enum field pppoe-code :: <unsigned-byte> = 0,
    mappings: { #x0 <=> #"session data",
                #x7 <=> #"PADO (PPPoE Active Discovery Offer)",
                #x9 <=> #"PADI (PPPoE Active Discovery Initiation)",
                #x19 <=> #"PADR (PPPoE Active Discovery Request)",
                #x65 <=> #"PADS (PPPoE Active Discovery Session-confirmation)",
                #xa7 <=> #"PADT (PPPoE Active Discovery Termination)" };
  field session-id :: <2byte-big-endian-unsigned-integer> = 0;
  field pppoe-length :: <2byte-big-endian-unsigned-integer>,
    fixup: reduce(\+, 0, map(compose(byte-offset, frame-size),
                             frame.pppoe-tags));
  repeated field pppoe-tags :: <pppoe-tag>,
    reached-end?: instance?(frame, <pppoe-end-of-list>);
end;

define abstract protocol pppoe-tag (variably-typed-container-frame)
  length (frame.tag-length + 4) * 8;
  layering field tag-type :: <2byte-big-endian-unsigned-integer>;
  field tag-length :: <2byte-big-endian-unsigned-integer>,
    fixup: byte-offset(frame-size(frame)) - 4;
end;

define protocol pppoe-end-of-list (pppoe-tag)
  over <pppoe-tag> #x0;
end;

define protocol pppoe-service-name (pppoe-tag)
  over <pppoe-tag> #x0101;
  field service-name :: <externally-delimited-string>
    = $empty-externally-delimited-string;
end;

define protocol pppoe-access-contentrator-name (pppoe-tag)
  over <pppoe-tag> #x0102;
  field access-concentrator-name :: <externally-delimited-string>;
end;

define protocol pppoe-host-uniq (pppoe-tag)
  over <pppoe-tag> #x0103;
  field custom-data :: <raw-frame>;
end;

define protocol pppoe-access-concentrator-cookie (pppoe-tag)
  over <pppoe-tag> #x0104;
  field custom-data :: <raw-frame>;  
end;

define protocol pppoe-vendor-specific (pppoe-tag)
  over <pppoe-tag> #x0105;
  field reserved :: <unsigned-byte> = 0;
  field vendor-id :: <3byte-big-endian-unsigned-integer>;
  field custom-data :: <raw-frame>;
end;

define protocol pppoe-relay-session-id (pppoe-tag)
  over <pppoe-tag> #x0110;
  field custom-data :: <raw-frame>;
end;

define protocol pppoe-hurl (pppoe-tag)
  over <pppoe-tag> #x0111;
  field pppoe-url :: <externally-delimited-string>;
end;

define protocol pppoe-service-name-error (pppoe-tag)
  over <pppoe-tag> #x0201;
  field error-message :: <raw-frame>;
end;

define protocol pppoe-access-concentrator-system-error (pppoe-tag)
  over <pppoe-tag> #x0202;
  field error-message :: <raw-frame>;
end;

define protocol pppoe-generic-error (pppoe-tag)
  over <pppoe-tag> #x0203;
  field error-message :: <externally-delimited-string>;
end;

