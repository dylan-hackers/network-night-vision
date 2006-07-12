module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define protocol logical-link-control (header-frame)
  summary "%s", compose(summary, payload);
  field type-code :: <2byte-big-endian-unsigned-integer>;
  variably-typed-field payload,
    type-function:
      select (frame.type-code)
        #x800 => <ipv4-frame>;
        #x806 => <arp-frame>;
          otherwise <raw-frame>;
      end;  
end;

define protocol link-control (header-frame)
  summary "%s", compose(summary, payload);
  field dsap :: <unsigned-byte>;
  field ssap :: <unsigned-byte>;
  field control :: <unsigned-byte>;
  field organisation-code :: <3byte-big-endian-unsigned-integer>;
  field payload :: <logical-link-control>;
end;
