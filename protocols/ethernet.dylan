module: ethernet
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

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

define n-byte-vector(mac-address, 6) end;

define method read-frame(type == <mac-address>,
                         string :: <string>)
 => (res)
  let res = as-lowercase(string);
  if (any?(method(x) x = ':' end, res))
    //input: 00:de:ad:be:ef:00
    let fields = split(res, ':');
    unless(fields.size = 6)
      signal(make(<parse-error>))
    end;
    make(<mac-address>,
         data: map-as(<stretchy-vector-subsequence>, rcurry(string-to-integer, base: 16), fields));
  else
    //input: 00deadbeef00
    unless (res.size = 12)
      signal(make(<parse-error>));
    end;
    let data = make(<byte-vector>, size: 6);
    for (i from 0 below data.size)
      data[i] := string-to-integer(res, start: i * 2, end: (i + 1) * 2, base: 16);
    end;
    make(<mac-address>, data: data);
  end;
end;

define method as (class == <string>, frame :: <mac-address>) => (string :: <string>);
  reduce1(method(a, b) concatenate(a, ":", b) end,
          map-as(<stretchy-vector>,
                 rcurry(integer-to-string, base: 16, size: 2),
                 frame.data))
end;

define protocol ethernet-frame (header-frame)
  summary "ETH %= -> %=", source-address, destination-address;
  field destination-address :: <mac-address>;
  field source-address :: <mac-address>;
  layering field type-code :: <2byte-big-endian-unsigned-integer>;
  variably-typed-field payload,
    type-function: if (frame.type-code > 1500)
                     payload-type(frame)
                   else
                     <llc-frame>
                   end;
end;

define protocol llc-frame (header-frame)
  field dsap :: <7bit-unsigned-integer>;
  field address-type-designation :: <1bit-unsigned-integer>;
  field ssap :: <7bit-unsigned-integer>;
  field command-response-identifer :: <1bit-unsigned-integer>;
  field control :: <unsigned-byte>;
  variably-typed-field payload,
    type-function: case
                     frame.dsap = 85 & frame.ssap = 85 => <snap-frame>;
                     frame.dsap = 33 & frame.ssap = 33 => <stp-frame>;
                     otherwise => <raw-frame>;
                   end;
end;

define protocol snap-frame (header-frame)
  field organization-code :: <3byte-big-endian-unsigned-integer> = 0;
  layering field type-code :: <2byte-big-endian-unsigned-integer>;
  variably-typed-field payload,
    type-function: lookup-layer(<ethernet-frame>, frame.type-code) | <raw-frame>;
end;

define protocol vlan-tag (header-frame)
  over <ethernet-frame> #x8100;
  summary "VLAN: %=", vlan-id;
  field priority :: <3bit-unsigned-integer> = 0;
  field canonical-format-indicator :: <1bit-unsigned-integer> = 0;
  field vlan-id :: <12bit-unsigned-integer>;
  layering field type-code :: <2byte-big-endian-unsigned-integer>;
  variably-typed-field payload,
    type-function: lookup-layer(<ethernet-frame>, frame.type-code) | <raw-frame>;
end;

define protocol stp-identifier (container-frame)
  summary "%=/%=", bridge-priority, bridge-address;
  field bridge-priority :: <2byte-big-endian-unsigned-integer>;
  field bridge-address :: <mac-address>;
end;

define abstract protocol stp-frame (variably-typed-container-frame)
  field protocol-identifier :: <2byte-big-endian-unsigned-integer>;
  field protocol-version :: <unsigned-byte>;
  layering field bpdu-type :: <unsigned-byte>;
end;

define protocol stp-configuration-frame (stp-frame)
  summary "STP configuration";
  over <stp-frame> 0;
  field flags :: <unsigned-byte>;
  field root-identifier :: <stp-identifier>;
  field root-path-cost :: <big-endian-unsigned-integer-4byte>;
  field bridge-identifier :: <stp-identifier>;
  field port-identifier :: <2byte-big-endian-unsigned-integer>;
  field message-age :: <2byte-big-endian-unsigned-integer>;
  field max-age :: <2byte-big-endian-unsigned-integer>;
  field hello-time :: <2byte-big-endian-unsigned-integer>;
  field forward-delay :: <2byte-big-endian-unsigned-integer>;
end;

define protocol stp-topology-change-frame (stp-frame)
  over <stp-frame> #x80;
  summary "STP topology change notification";
end;

define abstract protocol cdp-record (variably-typed-container-frame)
  length frame.cdp-length * 8;
  layering field cdp-type :: <2byte-big-endian-unsigned-integer>;
  field cdp-length :: <2byte-big-endian-unsigned-integer>,
    fixup: byte-offset(frame-size(frame));
end;

define abstract protocol cdp-unknown-record (cdp-record)
  field cdp-value :: <raw-frame>;
end;

define abstract protocol cdp-string-record (cdp-record)
  field cdp-value :: <externally-delimited-string>;
end;

define protocol cdp-device-id (cdp-string-record)
  over <cdp-record> #x1;
  summary "ID: %=", cdp-value;
end;

define protocol cdp-address-frame (container-frame)
  field cdp-protocol-type :: <unsigned-byte>;
  field cdp-protocol-length :: <unsigned-byte>;
  field cdp-protocol :: <raw-frame>, length: frame.cdp-protocol-length * 8;
  field cdp-address-length :: <2byte-big-endian-unsigned-integer>;
  field cdp-address :: <raw-frame>, length: frame.cdp-address-length * 8;
end; 

define protocol cdp-addresses-frame (cdp-record)
  over <cdp-record> #x2;
  // FIXME: field address-count :: <big-endian-unsigned-integer-4byte>;
  field address-count-first :: <unsigned-byte>;
  field address-count :: <3byte-big-endian-unsigned-integer>;
  repeated field cdp-addresses :: <cdp-address-frame>,
    count: frame.address-count;
end;

define protocol cdp-port-id (cdp-string-record)
  over <cdp-record> #x3;
  summary "Port: %=", cdp-value;
end;

define protocol cdp-capabilities (cdp-record)
  over <cdp-record> #x4;
  field padding1 :: <3byte-big-endian-unsigned-integer>;
  field padding2 :: <1bit-unsigned-integer>;
  field cdp-layer1 :: <1bit-unsigned-integer>;
  field cdp-no-igmp :: <1bit-unsigned-integer>;
  field cdp-layer3-host :: <1bit-unsigned-integer>;
  field cdp-layer2-switching :: <1bit-unsigned-integer>;
  field cdp-layer2-source-route :: <1bit-unsigned-integer>;
  field cdp-layer2-transparent :: <1bit-unsigned-integer>;
  field cdp-layer3 :: <1bit-unsigned-integer>;
end;

define protocol cdp-version (cdp-string-record)
  over <cdp-record> #x5;
  summary "Version: %=", cdp-value;
end;

define protocol cdp-platform (cdp-string-record)
  over <cdp-record> #x6;
  summary "Platform: %=", cdp-value;
end;

define protocol cdp-ip-prefix (container-frame)
  field ip-address :: <raw-frame>, length: 32;
  field netmask :: <unsigned-byte>;
end;

define protocol cdp-ip-prefixes (cdp-record)
  over <cdp-record> #x7;
  field ip-prefix-count :: <unsigned-byte>;
  repeated field ip-prefixes :: <cdp-ip-prefix>,
    count: frame.ip-prefix-count;
end;

define protocol cdp-vtp-management-domain (cdp-string-record)
  over <cdp-record> #x9;
  summary "VTP Management domain: %=", cdp-value;
end;

define protocol cdp-vtp-native-vlan-id (cdp-record)
  over <cdp-record> #xa;
  summary "VTP native VLAN: %=", cdp-native-vlan-id;
  field cdp-native-vlan-id :: <2byte-big-endian-unsigned-integer>;
end;

define protocol cdp-duplex-frame (cdp-record)
  over <cdp-record> #xb;
  summary "Duplex: %s", method(x) if (x.cdp-duplex = 0) "half" else "full" end end;
  field cdp-duplex :: <unsigned-byte>;
end;

define protocol cdp-hello (cdp-unknown-record)
  over <cdp-record> #x8;
  summary "Hello (undocumented)";
end;

define protocol cdp-ata-186-voip-vlan-request (cdp-unknown-record)
  over <cdp-record> #xe;
  summary "ATA 186 VoIP VLAN Request";
end;

define protocol cdp-ata-186-voip-vlan-assignment (cdp-unknown-record)
  over <cdp-record> #xf;
  summary "ATA 186 VoIP VLAN Assignment";
end;

define protocol cdp-power (cdp-unknown-record)
  over <cdp-record> #x10;
  summary "Power: %=", cdp-value;
end;

define protocol cdp-mtu-frame (cdp-record)
  over <cdp-record> #x11;
  summary "MTU: %=", cdp-mtu;
  field cdp-mtu :: <big-endian-unsigned-integer-4byte>;
end;

define protocol cdp-avvid-trust-bitmap (cdp-unknown-record)
  over <cdp-record> #x12;
  summary "AVVID Trust Bitmap";
end;

define protocol cdp-avvid-untrusted-port-CoS (cdp-unknown-record)
  over <cdp-record> #x13;
  summary "AVVID Untrusted Port CoS";
end;

define protocol cdp-system-name (cdp-string-record)
  over <cdp-record> #x14;
  summary "System name: %=", cdp-value;
end;

define protocol cdp-system-object-id (cdp-unknown-record)
  over <cdp-record> #x16;
  summary "System OID: %=", cdp-value;
end;

define protocol cdp-physical-location (cdp-string-record)
  over <cdp-record> #x17;
  summary "Physical location: %=", cdp-value;
end;

define protocol cdp-frame (container-frame)
  over <ethernet-frame> #x2000;
  over <cisco-hdlc-frame> #x2000;
  summary "Cisco Discovery Protocol";
  field version :: <unsigned-byte>;
  field time-to-live :: <unsigned-byte>;
  field checksum :: <2byte-big-endian-unsigned-integer>;
  repeated field cdp-values :: <cdp-record>, reached-end?: #f;
end;

