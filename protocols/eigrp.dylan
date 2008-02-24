module: eigrp

//Enhanced Interior Gateway Routing Protocol (EIGRP)
//http://www.rhyshaden.com/eigrp.htm
//http://www.oreilly.com/catalog/iprouting/chapter/ch04.html

define protocol eigrp (container-frame)
  summary "EIGRP Opcode: %= AS Number: %=", opcode, autonomoussystem;
  over <ipv4-frame> 88;
  field version :: <unsigned-byte> = 2;
// Opcodes
// 1 - Update
// 2 - Request
// 3 - Query
// 4 - Replay
// 5 - Hello
  layering field opcode :: <unsigned-byte> = 5;
//checksum(this layer + payload)
  field checksum :: <2byte-big-endian-unsigned-integer>;
  field flags :: <big-endian-unsigned-integer-4byte> = 0;
  field sequence :: <big-endian-unsigned-integer-4byte> = 0;
  field acknowledge :: <big-endian-unsigned-integer-4byte> = 0;
  field autonomoussystem :: <big-endian-unsigned-integer-4byte> = 100;
end;
