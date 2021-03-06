module: ipv4
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define abstract binary-data <ip-option-frame> (<variably-typed-container-frame>)
  field copy-flag :: <1bit-unsigned-integer>;
  layering field option-type :: <7bit-unsigned-integer>;
end;

define binary-data <router-alert-ip-option> (<ip-option-frame>)
  over <ip-option-frame> 20;
  field router-alert-length :: <unsigned-byte> = 4;
  field router-alert-value :: <2byte-big-endian-unsigned-integer>;
end;

define binary-data <end-of-option-ip-option> (<ip-option-frame>)
  over <ip-option-frame> 0;
end;

define binary-data <no-operation-ip-option> (<ip-option-frame>)
  over <ip-option-frame> 1;
end;

define binary-data <security-ip-option-frame> (<ip-option-frame>)
  over <ip-option-frame> 2;
  field security-length :: <unsigned-byte>;
  field security :: <2byte-big-endian-unsigned-integer>;
  field compartments :: <2byte-big-endian-unsigned-integer>;
  field handling-restrictions :: <2byte-big-endian-unsigned-integer>;
  field transmission-control-code :: <3byte-big-endian-unsigned-integer>;
end;


define function calculate-checksum (frame :: <byte-sequence>,
                                    count :: <integer>) => (res :: <integer>)
  let checksum = 0.0d0;
  for (i from 0 below count - 1 by 2)
    checksum := checksum + ash(frame[i], 8) + frame[i + 1];
  end;
  if (logand(#x1, count) = 1)
    checksum := checksum + ash(frame[count - 1], 8);
  end;
  let (low, high) = floor/(checksum, 2 ^ 16);
  let res :: <integer> = round(high) + low;
  logand(#xffff, lognot(res));
end;

define method fixup! (frame :: <unparsed-ipv4-frame>,
                      #next next-method)
  frame.header-checksum := calculate-checksum(frame.packet, frame.header-length * 4);
  next-method();
end;

define binary-data <ipv4-frame> (<header-frame>)
  summary "IP SRC %= DST %=", source-address, destination-address;
  over <ethernet-frame> #x800;
  over <cisco-hdlc-frame> #x800;
  over <link-control> #x800;
  over <ppp> #x21;
  field version :: <4bit-unsigned-integer> = 4;
  field header-length :: <4bit-unsigned-integer>,
    fixup: ceiling/(reduce(\+, 20,
                           map(compose(byte-offset, frame-size),
                               frame.options)),
                    4);
  field type-of-service :: <unsigned-byte> = 0;
  field total-length :: <2byte-big-endian-unsigned-integer>,
    fixup: frame.header-length * 4 + byte-offset(frame-size(frame.payload));
  field identification :: <2byte-big-endian-unsigned-integer> = 23;
  field evil :: <1bit-unsigned-integer> = 0;
  field dont-fragment :: <1bit-unsigned-integer> = 0;
  field more-fragments :: <1bit-unsigned-integer> = 0;
  field fragment-offset :: <13bit-unsigned-integer> = 0;
  field time-to-live :: <unsigned-byte> = 64;
  layering field protocol :: <unsigned-byte>;
  field header-checksum :: <2byte-big-endian-unsigned-integer> = 0;
  field source-address :: <ipv4-address>;
  field destination-address :: <ipv4-address>;
  repeated field options :: <ip-option-frame> = make(<stretchy-vector>),
    reached-end?: instance?(frame, <end-of-option-ip-option>);
  variably-typed field payload,
    start: frame.header-length * 4 * 8,
    end: frame.total-length * 8;
end;



define binary-data <udp-frame> (<header-frame>)
  summary "UDP port %= -> %=", source-port, destination-port;
  over <ipv4-frame> 17;
  field source-port :: <2byte-big-endian-unsigned-integer>;
  layering field destination-port :: <2byte-big-endian-unsigned-integer>;
  field payload-size :: <2byte-big-endian-unsigned-integer>,
    fixup: byte-offset(frame-size(frame.payload)) + 8;
  field checksum :: <2byte-big-endian-unsigned-integer> = 0;
  variably-typed field payload,
    end: frame.payload-size * 8,
    type-function:
      lookup-layer(frame.object-class, frame.layer-magic) |
        lookup-layer(frame.object-class, frame.source-port) |
          <raw-frame>
end;

define binary-data <arp-frame> (<container-frame>)
  over <ethernet-frame> #x806;
  over <link-control> #x806;
  field mac-address-type :: <2byte-big-endian-unsigned-integer> = 1;
  field protocol-address-type :: <2byte-big-endian-unsigned-integer> = #x800;
  field mac-address-size :: <unsigned-byte> = byte-offset(field-size(<mac-address>));
  field protocol-address-size :: <unsigned-byte>
    = byte-offset(field-size(<ipv4-address>));
  enum field operation :: <2byte-big-endian-unsigned-integer>,
    mappings: { #x1 <=> #"arp-request",
                #x2 <=> #"arp-response" };
  field source-mac-address :: <mac-address>;
  field source-ip-address :: <ipv4-address>;
  field target-mac-address :: <mac-address>;
  field target-ip-address :: <ipv4-address>;
end;

define method summary (frame :: <arp-frame>) => (res :: <string>)
  if(frame.operation = #"arp-request")
    format-to-string("ARP WHO-HAS %= tell %=",
                     frame.target-ip-address,
                     frame.source-ip-address)
  elseif(frame.operation = #"arp-response")
    format-to-string("ARP %= IS-AT %=",
                     frame.source-ip-address,
                     frame.source-mac-address)
  else
    format-to-string("ARP (bogus op %=)", frame.operation)
  end
end;


