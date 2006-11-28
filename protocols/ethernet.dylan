module: ethernet
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

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
  field dsap :: <unsigned-byte>;
  field ssap :: <unsigned-byte>;
  field control :: <unsigned-byte>;
  variably-typed-field payload,
    type-function: case
                     frame.dsap = 170 & frame.ssap = 170 => <snap-frame>;
                     frame.dsap = 66 & frame.ssap = 66 => <stp-frame>;
                     otherwise => <raw-frame>;
                   end;
end;

define protocol snap-frame (header-frame)
  field organization-code :: <3byte-big-endian-unsigned-integer> = 0;
  layering field type-code :: <2byte-big-endian-unsigned-integer>;
  variably-typed-field payload,
    type-function: element(<ethernet-frame>.layer, frame.type-code, default: <raw-frame>);
end;

define protocol stp-identifier (container-frame)
  summary "%=/%=", bridge-priority, bridge-address;
  field bridge-priority :: <2byte-big-endian-unsigned-integer>;
  field bridge-address :: <mac-address>;
end;

define protocol stp-frame (container-frame)
  field protocol-identifier :: <2byte-big-endian-unsigned-integer>;
  field protocol-version :: <unsigned-byte>;
  field bpdu-type :: <unsigned-byte>;
end;

define method parse-frame (frame-type == <stp-frame>,
                           packet :: <byte-sequence>,
                           #key parent)
 => (value :: <stp-frame>, next-unparsed :: <integer>);
  let bpdu-type = next-method().bpdu-type;
  let bpdu-class = select (bpdu-type)
                     0    => <stp-configuration-frame>;
                     #x80 => <stp-topology-change-frame>;
                     otherwise => signal(make(<malformed-packet-error>));
                   end;
  parse-frame(bpdu-class, packet, parent: parent);
end;

define protocol stp-configuration-frame (stp-frame)
  summary "STP configuration";
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
  summary "STP topology change notification";
end;

define protocol cdp-record (container-frame)
  field cdp-type :: <2byte-big-endian-unsigned-integer>;
  field cdp-length :: <2byte-big-endian-unsigned-integer>;
end;

define method parse-frame (frame-type == <cdp-record>,
                           packet :: <byte-sequence>,
                           #key parent)
 => (value :: <cdp-record>, next-unparsed :: false-or(<integer>));
  let bpdu-type = next-method().cdp-type;
  let bpdu-class = select (bpdu-type)
                     #x0001 => <cdp-device-id>;
                     #x0002 => <cdp-addresses>;
                     #x0003 => <cdp-port-id>;
                     #x0004 => <cdp-capabilities>;
                     #x0005 => <cdp-version>;
                     #x0006 => <cdp-platform>;
                     #x0007 => <cdp-ip-prefixes>;
                     #x0008 => <cdp-hello>;
                     #x0009 => <cdp-vtp-management-domain>;
                     #x000a => <cdp-vtp-native-vlan-id>;
                     #x000b => <cdp-duplex>;
                     #x000e => <cdp-ata-186-voip-vlan-request>;
                     #x0010 => <cdp-ata-186-voip-vlan-assignment>;
                     #x0011 => <cdp-mtu>;
                     #x0012 => <cdp-avvid-trust-bitmap>;
                     #x0013 => <cdp-avvid-untrusted-port-CoS>;
                     #x0014 => <cdp-system-name>;
                     #x0016 => <cdp-system-object-id>;
                     #x0017 => <cdp-physical-location>;
                     otherwise => <cdp-unknown-record>;
                   end;
  parse-frame(bpdu-class, packet, parent: parent);
end;

define protocol cdp-unknown-record (cdp-record)
  field cdp-value :: <raw-frame>, end: frame.cdp-length * 8;
end;

define protocol cdp-string-record (cdp-record)
  field cdp-value :: <externally-delimited-string>, end: frame.cdp-length * 8;
end;

define protocol cdp-device-id (cdp-string-record)
  summary "ID: %=", cdp-value;
end;

define protocol cdp-address (container-frame)
  field cdp-protocol-type :: <unsigned-byte>;
  field cdp-protocol-length :: <unsigned-byte>;
  field cdp-protocol :: <raw-frame>, length: frame.cdp-protocol-length * 8;
  field cdp-address-length :: <unsigned-byte>;
  field cdp-address :: <raw-frame>, length: frame.cdp-address-length * 8;
end; 

define protocol cdp-addresses (cdp-record)
  field address-count :: <unsigned-byte>;
  repeated field cdp-addresses :: <cdp-address>,
    count: frame.address-count;
  field padding :: <raw-frame>, end: frame.cdp-length * 8;
end;

define protocol cdp-port-id (cdp-string-record)
  summary "Port: %=", cdp-value;
end;

define protocol cdp-capabilities (cdp-record)
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
  summary "Version: %=", cdp-value;
end;

define protocol cdp-platform (cdp-string-record)
  summary "Platform: %=", cdp-value;
end;

define protocol cdp-ip-prefix (container-frame)
  field ip-address :: <raw-frame>, length: 32;
  field netmask :: <unsigned-byte>;
end;

define protocol cdp-ip-prefixes (cdp-record)
  field ip-prefix-count :: <unsigned-byte>;
  repeated field ip-prefixes :: <cdp-ip-prefix>,
    count: frame.ip-prefix-count;
end;

define protocol cdp-vtp-management-domain (cdp-string-record)
  summary "VTP Management domain: %=", cdp-value;
end;

define protocol cdp-vtp-native-vlan-id (cdp-record)
  summary "VTP native VLAN: %=", cdp-native-vlan-id;
  field cdp-native-vlan-id :: <2byte-big-endian-unsigned-integer>;
end;

define protocol cdp-duplex (cdp-record)
  summary "Duplex: %s", method(x) if (x.cdp-duplex = 0) "half" else "full" end end;
  field cdp-duplex :: <unsigned-byte>;
end;

define protocol cdp-hello (cdp-unknown-record)
  summary "Hello (undocumented)";
end;

define protocol cdp-ata-186-voip-vlan-request (cdp-unknown-record)
  summary "ATA 186 VoIP VLAN Request";
end;

define protocol cdp-ata-186-voip-vlan-assignment (cdp-unknown-record)
  summary "ATA 186 VoIP VLAN Assignment";
end;

define protocol cdp-mtu (cdp-record)
  summary "MTU: %=", cdp-mtu;
  field cdp-mtu :: <big-endian-unsigned-integer-4byte>;
end;

define protocol cdp-avvid-trust-bitmap (cdp-unknown-record)
  summary "AVVID Trust Bitmap";
end;

define protocol cdp-avvid-untrusted-port-CoS (cdp-unknown-record)
  summary "AVVID Untrusted Port CoS";
end;

define protocol cdp-system-name (cdp-string-record)
  summary "System name: %=", cdp-value;
end;

define protocol cdp-system-object-id (cdp-unknown-record)
  summary "System OID: %=", cdp-value;
end;

define protocol cdp-physical-location (cdp-string-record)
  summary "Physical location: %=", cdp-value;
end;

define protocol cdp-frame (container-frame)
  over <ethernet-frame> #x2000;
  summary "Cisco Discovery Protocol";
  field version :: <unsigned-byte>;
  field time-to-live :: <unsigned-byte>;
  field checksum :: <2byte-big-endian-unsigned-integer>;
  repeated field cdp-values :: <cdp-record>, reached-end?: #f;
end;

