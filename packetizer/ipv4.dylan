module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define protocol ip-option-type-frame (container-frame)
  field flag :: <1bit-unsigned-integer>;
  field class :: <2bit-unsigned-integer>;
  field number :: <5bit-unsigned-integer>;
end;

define protocol ip-option-frame (container-frame)
  field option-type :: <ip-option-type-frame>;
end;

define method parse-frame (frame-type == <ip-option-frame>,
                           packet :: <byte-sequence>,
                           #key start :: <integer> = 0)
 => (value :: <ip-option-frame>, next-unparsed :: <integer>)
  let ip-option-type = parse-frame(<ip-option-type-frame>, packet, start: start);
  let option-frame-type
    = select (ip-option-type.class)
        0 => select (ip-option-type.number)
               0 => <end-of-option-ip-option>;
               1 => <no-operation-ip-option>;
               2 => <security-ip-option>;
               3 => <loose-source-and-record-route-ip-option>;
               9 => <strict-source-and-record-route-ip-option>;
               7 => <record-route-ip-option>;
               8 => <stream-id-ip-option>;
               20 => <router-alert-ip-option>;
               otherwise => signal(make(<malformed-packet-error>))
             end;
        1 => select (ip-option-type.class)
               1 => <general-error-ip-option>;
               otherwise => signal(make(<malformed-packet-error>))
             end;
        2 => select (ip-option-type.class)
               4 => <internet-timestamp-ip-option>;
               5 => <satellite-timestamp-ip-option>;
               otherwise => signal(make(<malformed-packet-error>))
             end;
        otherwise => signal(make(<malformed-packet-error>))
      end;
   parse-frame(option-frame-type, packet, start: start);
end;

define protocol router-alert-ip-option (ip-option-frame)
  field length :: <unsigned-byte> = 4;
  field value :: <2byte-big-endian-unsigned-integer>;
end;

define protocol end-of-option-ip-option (ip-option-frame)
end;

define protocol no-operation-ip-option (ip-option-frame)
end;

define protocol security-ip-option-frame (ip-option-frame)
  field length :: <unsigned-byte>;
  field security :: <2byte-big-endian-unsigned-integer>;
  field compartments :: <2byte-big-endian-unsigned-integer>;
  field handling-restrictions :: <2byte-big-endian-unsigned-integer>;
  field transmission-control-code :: <3byte-big-endian-unsigned-integer>;
end;

define n-byte-vector(ipv4-address, 4) end;

define method read-frame (frame-type == <ipv4-address>, string :: <string>)
 => (res)
  make(<ipv4-address>,
       data: map-as(<stretchy-vector-subsequence>, string-to-integer, split(string, '.')));
end;

define method as (class == <string>, frame :: <ipv4-address>) => (string :: <string>);
  reduce1(method(a, b) concatenate(a, ".", b) end,
          map-as(<stretchy-vector>,
                 integer-to-string,
                 frame.data))
end;

define method print-object (object :: <frame>, stream :: <stream>) => ()
  write(stream, as(<string>, object));
end;

define function calculate-checksum (frame :: type-union(<byte-vector-subsequence>, <byte-vector>),
                                    count :: <integer>) => (res :: <integer>)
  let checksum :: <integer> = 0;
  for (i from 0 below count - 1 by 2)
    checksum := checksum + ash(frame[i], 8) + frame[i + 1];
  end;
  if (logand(#x1, count) = 1)
    checksum := checksum + ash(frame[count - 1], 8);
  end;
  while (checksum > (2 ^ 16 - 1))
    checksum := ash(checksum, -16) + logand(#xffff, checksum);
  end;
  logand(#xffff, lognot(checksum));
end;

define method fixup! (frame :: <unparsed-ipv4-frame>,
                      #next next-method)
  frame.header-checksum := calculate-checksum(frame.packet, frame.header-length * 4);
  next-method();
end;

define method fixup! (frame :: <unparsed-icmp-frame>,
                      #next next-method)
  frame.checksum := calculate-checksum(frame.packet, frame.packet.size);
  next-method();
end;

define protocol ipv4-frame (header-frame)
  summary "IP SRC %= DST %=/%s",
    source-address, destination-address, compose(summary, payload);
  field version :: <4bit-unsigned-integer> = 4;
  field header-length :: <4bit-unsigned-integer>,
    fixup: ceiling/(reduce(\+, 20, map(method(x) byte-offset(frame-size(x)) end, frame.options)), 4);
  field type-of-service :: <unsigned-byte> = 0;
  field total-length :: <2byte-big-endian-unsigned-integer>,
    fixup: frame.header-length * 4 + byte-offset(frame-size(frame.payload));
  field identification :: <2byte-big-endian-unsigned-integer> = 23;
  field evil :: <1bit-unsigned-integer> = 0;
  field dont-fragment :: <1bit-unsigned-integer> = 0;
  field more-fragments :: <1bit-unsigned-integer> = 0;
  field fragment-offset :: <13bit-unsigned-integer> = 0;
  field time-to-live :: <unsigned-byte> = 64;
  field protocol :: <unsigned-byte>;
  field header-checksum :: <2byte-big-endian-unsigned-integer> = 0;
  field source-address :: <ipv4-address>;
  field destination-address :: <ipv4-address>;
  repeated field options :: <ip-option-frame> = make(<stretchy-vector>),
    reached-end?: method(value :: <ip-option-frame>)
                      instance?(value, <end-of-option-ip-option>)
                  end;
  variably-typed-field payload,
    start: frame.header-length * 4 * 8,
    end: frame.total-length * 8,
    type-function: payload-type(frame);
end;

define layer-bonding <ipv4-frame> (protocol)
  1 => <icmp-frame>;
  6 => <tcp-frame>;
  17 => <udp-frame>
end;


define protocol icmp-frame (header-frame)
  summary "ICMP type %= code %=", type, code;
  field type :: <unsigned-byte>;
  field code :: <unsigned-byte>;
  field checksum :: <2byte-big-endian-unsigned-integer> = 0;
  field payload :: <raw-frame>;
end;

define protocol udp-frame (header-frame)
  summary "UDP port %= -> %=/%s", source-port, destination-port, compose(summary, payload);
  field source-port :: <2byte-big-endian-unsigned-integer>;
  field destination-port :: <2byte-big-endian-unsigned-integer>;
  field length :: <2byte-big-endian-unsigned-integer>,
    fixup: byte-offset(frame-size(frame.payload)) + 8;
  field checksum :: <2byte-big-endian-unsigned-integer> = 0;
  variably-typed-field payload,
    end: frame.length * 8,
    type-function: payload-type(frame);
end;

define inline method payload-type (frame :: <udp-frame>) => (res :: <type>)
  select (frame.source-port)
    53 => <dns-frame>;
    5353 => <dns-frame>;
    otherwise => select (frame.destination-port)
                   53 => <dns-frame>;
                   5353 => <dns-frame>;
                   otherwise => <raw-frame>;
                 end;
  end;
end;

// FIXME: must do for now
define n-byte-vector(big-endian-unsigned-integer-4byte, 4) end;

define protocol tcp-frame (header-frame)
  summary "TCP %s port %= -> %=", flags-summary, source-port, destination-port;
  field source-port :: <2byte-big-endian-unsigned-integer>;
  field destination-port :: <2byte-big-endian-unsigned-integer>;
  field sequence-number :: <big-endian-unsigned-integer-4byte>;
  field acknowledgement-number :: <big-endian-unsigned-integer-4byte>;
  field data-offset :: <4bit-unsigned-integer>,
   fixup: ceiling/(20 + byte-offset(frame-size(frame.options-and-padding)), 4);
  field reserved :: <6bit-unsigned-integer> = 0;
  field urg :: <1bit-unsigned-integer> = 0;
  field ack :: <1bit-unsigned-integer> = 0;
  field psh :: <1bit-unsigned-integer> = 0;
  field rst :: <1bit-unsigned-integer> = 0;
  field syn :: <1bit-unsigned-integer> = 0;
  field fin :: <1bit-unsigned-integer> = 0;
  field window :: <2byte-big-endian-unsigned-integer> = 0;
  field checksum :: <2byte-big-endian-unsigned-integer> = 0;
  field urgent-pointer :: <2byte-big-endian-unsigned-integer> = 0;
  field options-and-padding :: <raw-frame> = make(<raw-frame>, data: make(<stretchy-byte-vector-subsequence>));
  field payload :: <raw-frame> = make(<raw-frame>, data: make(<stretchy-byte-vector-subsequence>)),
    start: frame.data-offset * 4 * 8;
end;

define protocol pseudo-header (container-frame)
  field source-address :: <ipv4-address>;
  field destination-address :: <ipv4-address>;
  field reserved :: <unsigned-byte> = 0;
  field protocol :: <unsigned-byte> = 6;
  field segment-length :: <2byte-big-endian-unsigned-integer>;
  field data :: <raw-frame>,
    length: frame.segment-length;
end;

define method fixup!(tcp-frame :: <unparsed-tcp-frame>,
                     #next next-method)
  let pseudo-header = make(<pseudo-header>,
                           source-address: tcp-frame.parent.source-address,
                           destination-address: tcp-frame.parent.destination-address,
                           segment-length: tcp-frame.packet.size,
                           data: make(<raw-frame>, data: tcp-frame.packet));
  let pack = assemble-frame(pseudo-header).packet;
  tcp-frame.checksum := calculate-checksum(pack, pack.size);
  next-method();
end;

define method flags-summary (frame :: <tcp-frame>) => (result :: <string>)
  apply(concatenate,
        map(method(field, id) if (frame.field = 1) id else "" end end,
            list(urg, ack, psh, rst, syn, fin),
            list("U", "A", "P", "R", "S", "F")))
end;
              
define protocol arp-frame (container-frame)
  field mac-address-type :: <2byte-big-endian-unsigned-integer> = 1;
  field protocol-address-type :: <2byte-big-endian-unsigned-integer> = #x800;
  field mac-address-size :: <unsigned-byte> = byte-offset(field-size(<mac-address>));
  field protocol-address-size :: <unsigned-byte> 
    = byte-offset(field-size(<ipv4-address>));
  field operation :: <2byte-big-endian-unsigned-integer>;
  field source-mac-address :: <mac-address>;
  field source-ip-address :: <ipv4-address>;
  field target-mac-address :: <mac-address>;
  field target-ip-address :: <ipv4-address>;
end;

define method summary (frame :: <arp-frame>) => (res :: <string>)
  if(frame.operation = 1)
    format-to-string("ARP WHO-HAS %= tell %=",
                     frame.target-ip-address,
                     frame.source-ip-address)
  elseif(frame.operation = 2)
    format-to-string("ARP %= IS-AT %=",
                     frame.source-ip-address,
                     frame.source-mac-address)
  else
    format-to-string("ARP (bogus op %=)", frame.operation)
  end
end;


