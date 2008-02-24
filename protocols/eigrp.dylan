module: eigrp

//Enhanced Interior Gateway Routing Protocol (EIGRP)
//http://www.rhyshaden.com/eigrp.htm
//http://www.oreilly.com/catalog/iprouting/chapter/ch04.html
define protocol eigrp (container-frame)
  summary "EIGRP Opcode: %= AS Number: %=", opcode, autonomoussystem;
  over <ipv4-frame> 88;
  field version :: <unsigned-byte> = 2;
  enum field opcode :: <unsigned-byte> = 5,
    mappings: { 1 <=> #"update",
                2 <=> #"request",
                3 <=> #"query",
                4 <=> #"rely",
                5 <=> #"hello" };
//checksum(this layer + payload)
  field checksum :: <2byte-big-endian-unsigned-integer>;
  field flags :: <big-endian-unsigned-integer-4byte> = 0;
  field sequence :: <big-endian-unsigned-integer-4byte> = 0;
  field acknowledge :: <big-endian-unsigned-integer-4byte> = 0;
  field autonomoussystem :: <big-endian-unsigned-integer-4byte> = 100;
  repeated field tlv-payload :: <eigrp-tlv>, reached-end?: #f;
end;

define abstract protocol eigrp-tlv (variably-typed-container-frame)
  layering field tlv-type :: <2byte-big-endian-unsigned-integer>;
  field tlv-length :: <2byte-big-endian-unsigned-integer>;
end;

define abstract protocol eigrp-parameters (eigrp-tlv)
  over <eigrp-tlv> 1;
  field k1 :: <unsigned-byte> = 1;
  field k2 :: <unsigned-byte> = 0;
  field k3 :: <unsigned-byte> = 1;
  field k4 :: <unsigned-byte> = 0;
  field k5 :: <unsigned-byte> = 0;
  field reserved :: <unsigned-byte> = 0;
  field hold-time :: <2byte-big-endian-unsigned-integer> = 15;
end;

define abstract protocol eigrp-authentication-data (eigrp-tlv)
  over <eigrp-tlv> 2;
  field authentication-data :: <raw-frame>, length: frame.tlv-length * 8 - 32;
end;

define abstract protocol eigrp-sequence (eigrp-tlv)
  over <eigrp-tlv> 3;
  field address-length :: <unsigned-byte> = 4;
  field ip-address :: <ipv4-address>;
end;

define abstract protocol eigrp-software-version (eigrp-tlv)
  over <eigrp-tlv> 4;
  field ios-version :: <2byte-big-endian-unsigned-integer>;
  field eigrp-version :: <2byte-big-endian-unsigned-integer>;
end;

define abstract protocol eigrp-next-multicast-sequence (eigrp-tlv)
  over <eigrp-tlv> 5;
  field next-multicast-sequence :: <big-endian-unsigned-integer-4byte> = 144;
end;

define abstract protocol eigrp-internal-route (eigrp-tlv)
  over <eigrp-tlv> 258;
  field next-hop :: <ipv4-address>;
  field delay :: <big-endian-unsigned-integer-4byte> = 0;
  field bandwidth :: <big-endian-unsigned-integer-4byte> = 0;
  field mtu :: <3byte-big-endian-unsigned-integer> = 1500;
  field hop-count :: <unsigned-byte> = 0;
  field reliability :: <unsigned-byte> = 0;
  field load :: <unsigned-byte> = 0;
  field reserved :: <2byte-big-endian-unsigned-integer> = 0;
  field prefix-length :: <unsigned-byte> = 24;
  // 25 bytes = next-hop + dely + bandwidth + mtu + hop-count + reliability +
  // load +reserved + prefix-length
  // zeros at the end of an ip address will be omitted
  field destination :: <raw-frame>, length: frame.tlv-length * 8 - 25 * 8;
end;

