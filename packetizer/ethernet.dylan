module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define n-byte-vector(<mac-address>, 6) end;

define method as (class == <string>, frame :: <mac-address>) => (string :: <string>);
  reduce1(method(a, b) concatenate(a, ":", b) end,
          map-as(<stretchy-vector>,
                 rcurry(integer-to-string, base: 16, size: 2),
                 frame.data))
end;

define protocol ethernet-frame (<header-frame>)
  summary "ETH %= -> %=/%s",
    source-address, destination-address, compose(summary, payload);
  field destination-address :: <mac-address>;
  field source-address :: <mac-address>;
  field type-code :: <2byte-big-endian-unsigned-integer>;
  variably-typed-field payload,
    type-function: select (frame.type-code)
                     #x800 => <ipv4-frame>;
                     #x806 => <arp-frame>;
                     otherwise <raw-frame>;
                   end;
end;
