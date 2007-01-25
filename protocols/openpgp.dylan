module: openpgp


define protocol multi-precision-integer (container-frame)
  field mpi-length :: <2byte-big-endian-unsigned-integer>;
  field real-mpi :: <raw-frame>, length: byte-offset(frame.mpi-length + 7);
end;
  
define protocol string-to-key (variably-typed-container-frame)
  layering field type :: <unsigned-byte>;
  field hash-algorithm :: <hash-algorithm>;
end;

define protocol simple-string-to-key (string-to-key)
  over <string-to-key> 0;
end;

define protocol salted-string-to-key (string-to-key)
  over <string-to-key> 1;
  field salt-value :: <raw-frame>, static-length: 8 * 8;
end;

define protocol iterated-and-salted-string-to-key (string-to-key)
  over <string-to-key> 3;
  field salt-value :: <raw-frame>, static-length: 8 * 8;
  field salt-count :: <unsigned-byte>;
end;


//#define EXPBIAS 6
// count = ((Int32)16 + (c & 15)) << ((c >> 4) + EXPBIAS);
//32bit-ints, c = count

define protocol openpgp-packet-header (variably-typed-container-frame)
  field always-one :: <1bit-unsigned-integer> = 1;
  layering field new-packet-format :: <1bit-unsigned-integer>;
end;

define protocol old-openpgp-packet (opengpg-packet-header)
  over <openpgp-packet-header> 0;
  field content-tag :: <4bit-unsigned-integer> = 0;
  field length-type :: <2bit-unsigned-integer>;
  variably-typed-field body-length,
    type-function: select (frame.length-type)
                     0 => <unsigned-byte>;
                     1 => <2byte-big-endian-unsigned-integer>;
                     2 => <4byte-big-endian-unsigned-integer>;
                     3 => <null-frame>;
                   end;
end;

define protocol new-openpgp-packet (openpgp-packet-header)
  over <openpgp-packet-header> 1;
  field content-tag :: <6bit-unsigned-integer>;
  field first-body-length :: <unsigned-byte>;
  variably-typed-field body-length,
    type-function: select (frame.first-body-length)
                     < 192 => <null-frame>;
                     < 224 => <unsigned-byte>;
                     < 255 => <null-frame>;
                     = 255 => <4byte-unsigned-integer>;
end;

define function get-length (f :: <new-openpgp-packet>) => (res :: <integer>)
  if (f.first-body-length < 192)
    f.first-body-length;
  elseif (f.first-body-length < 224)
    ash((f.first-body-length - 192), 8)+ f.body-length + 192;
  elseif (f.first-body-length < 255)
    ash(1, logand(f.first-body-length, #x1f));
  else
    f.body-length;
  end;
end;

//test-cases:
//100 -> 0x64
//1723 -> 0xc5 0xfb
//100000 -> 0xff 0x00 0x01 0x86 0xa0
//0xEF, first 32768 octets of data; 0xE1, next two octets of data; 0xE0, next one
//octet of data; 0xF0, next 65536 octets of data; 0xC5, 0xDD, last 1693
//octets of data

define protocol reserved-key-packet (container-frame)
  over <openpgp-packet-header> 0;
end;

define class <public-key-id> (<raw-frame>)
 size: 8 * 8;
end;
define protocol public-key-encrypted-session-key-packet (container-frame)
  over <openpgp-packet-header> 1;
  field version-number :: <unsigned-byte> = 3;
  field public-key-id :: <public-key-id>;
  field public-key-algorithm :: <public-key-algorithm>;
  field encrypted-session-key :: <raw-frame>; // <- mpi?!
end;

define protocol signature-packet (container-frame)
  over <openpgp-packet-header> 2;
  field version-number :: <unsigned-byte>;
end;

define protocol version3-signature-packet (signature-packet)
  over <signature-packet> 3;
  field hash-length :: <unsigned-byte> = 5;
  field signature-type :: <signature-type>;
  field creation-time :: <unix-time>;
  field signer-key-id :: <public-key-id>;
  field public-key-algorithm :: <public-key-algorithm>;
  field hash-algorithm :: <hash-algorithm>;
  field left-signed-hash-value :: <2byte-big-endian-unsigned-integer>;
  repeated field signature :: <multi-precision-integer>;
end;

//hash algos:
//MD2:        0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x02, 0x02
//MD5:        0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x02, 0x05
//RIPEMD-160: 0x2B, 0x24, 0x03, 0x02, 0x01
//SHA-1:      0x2B, 0x0E, 0x03, 0x02, 0x1A

define protocol version4-signature-packet (signature-packet)
  over <signature-packet> 4;
  field signature-type :: <signature-type>;
  field public-key-algorithm :: <public-key-algorithm>;
  field hash-algorithm :: <hash-algorithm>;
  repeated field hashed-subpackets :: <signature-subpacket>;
  field unhashed-packet-size :: <2byte-big-endian-unsigned-integer>;
  repeated field unhashed-subpackets :: <signature-subpacket>,
    length: frame.unhashed-packet-size * 8;
  field left-signed-hash-value :: <2byte-big-endian-unsigned-integer>;
  repeated field signature :: <multi-precision-integer>;
end;
define protocol signature-subpacket (container-frame)
  field first-subpacket-length :: <unsigned-byte>;
  variably-typed-field subpacket-length,
    type-function: select (frame.first-subpacket-length)
                     < 192 => <null-frame>;
                     < 255 => <unsigned-byte>;
                     = 255 => <4byte-unsigned-integer>
                   end;
  layering field subpacket-type :: <unsigned-byte>;
end;

define protocol boolean-signature-subpacket (signature-subpacket)
  field value? :: <unsigned-byte>;
end;

define protocol time-signature-subpacket (signature-subpacket)
  field timestamp :: <unix-time>;
end;

//   Bit 7 of the subpacket type is the "critical" bit.  If set, it
//   denotes that the subpacket is one that is critical for the evaluator
//   of the signature to recognize.  If a subpacket is encountered that is
//   marked critical but is unknown to the evaluating software, the
//   evaluator SHOULD consider the signature to be in error.


define protocol signature-creation-time (time-signature-subpacket)
  over <signature-subpacket> 2;
end;

define protocol signature-expiration-time (time-signature-subpacket)
  over <signature-subpacket> 3;
end;

define protocol exportable-certification (boolean-signature-subpacket)
  over <signature-subpacket> 4;
end;

define protocol trust-signature (signature-subpacket)
  over <signature-subpacket> 5;
  field level :: <unsigned-byte>;
  field trust-amount :: <unsigned-byte>;
end;

define protocol regular-expression (signature-subpacket)
  over <signature-subpacket> 6;
  field regular-expression :: <null-terminated-ascii-string>;
end;

define protocol revocable (boolean-signature-subpacket)
  over <signature-subpacket> 7;
end;

define protocol key-expiration-time (time-signature-subpacket)
  over <signature-subpacket> 9;
end;

define protocol backward-compatibility (signature-subpacket)
  over <signature-subpacket> 10;
end;

define protocol preferred-symmetric-algorithms (signature-subpacket)
  over <signature-subpacket> 11;
  repeated field algorithms :: <symmetric-cipher>;
end;

define protocol revocation-key (signature-subpacket)
  over <signature-subpacket> 12;
  field class :: <unsigned-byte>;
  field algorithm-id :: <unsigned-byte>;
  field fingerprint :: <raw-frame>, length: 20 * 8;
end;

define protocol issuer-key-id (signature-subpacket)
  over <signature-subpacket> 16;
  field issuer :: <public-key-id>;
end;

define protocol notation-data (signature-subpacket)
  over <signature-subpacket> 20;
  count repeated field flags :: <unsigned-byte> = 0, count: 4;
  field name-length :: <2byte-big-endian-unsigned-integer>;
  field value-length :: <2byte-big-endian-unsigned-integer>;
  field name-data :: <ascii-string>, length: frame.name-length * 8;
  field value-length :: <ascii-string>, length: frame.value-length * 8;
end;

define protocol preferred-hash-algorithms (signature-subpacket)
  over <signature-subpacket> 21;
  repeated field algorithms :: <hash-algorithm>;
end;

define protocol preferred-compression-algorithms (signature-subpacket)
  over <signature-subpacket> 22;
  repeated field algorithms :: <compression-algorithm>;
end;

define protocol key-server-preferences (signature-subpacket)
  over <signature-subpacket> 23;
  repeated field flags :: <unsigned-byte>;
end;

define protocol preferred-key-server (signature-subpacket)
  over <signature-subpacket> 24;
  field url :: <ascii-string>;
end;

define protocol primary-user-id (boolean-signature-subpacket)
  over <signature-subpacket> 25;
end;

define protocol policy-url (signature-subpacket)
  over <signature-subpacket> 26;
  field url :: <ascii-string>;
end;

define protocol key-flags (signature-subpacket)
  over <signature-subpacket> 27;
  repeated field flags :: <key-usage>;
end;

define enum-field key-usage (enum-frame)
  1 => #"certify other keys";
  2 => #"sign data";
  4 => #"encrypt communication";
  8 => #"encrypt storage";
  #x10 => #"split up by secret-sharing";
  #x80 => #"possession of more than one person";
end;

define protocol signers-user-id (signature-subpacket)
  over <signature-subpacket> 28;
  field user-id :: <public-key-id>;
end;

define protocol reason-for-revocation (signature-subpacket)
  over <signature-subpacket> 29;
  field revocation-code :: <revocation-code>;
  field reason-string :: <ascii-string>;
end;

define enum-field revocation-code (enum-frame)
  0 => #"no reason specified";
  1 => #"key superceded";
  2 => #"key compromised";
  3 => #"key no longer used";
  #x20 => #"user id no longer valid"
end;

define protocol symmetric-key-encrypted-session-key-packet (container-frame)
  over <openpgp-packet-header> 3;
  field version-number :: <unsigned-byte> = 4;
  field symmetric-algorithm :: <symmetric-cipher>;
  field string-to-key-specifier :: <??>;
  optional field encrypted-session-key :: <string-to-key>;
end;

define protocol one-pass-signature-packet (container-frame)
  over <openpgp-packet-header> 4;
  field version-number :: <unsigned-byte> = 3;
  field signature-type :: <signature-type>;
  field hash-algorithm :: <hash-algorithm>;
  field public-key-algorithm :: <public-key-algorithm>;
  field signing-key-id :: <public-key-id>;
  field nested? :: <unsigned-byte>;
end;

define protocol secret-key-packet (container-frame)
  over <openpgp-packet-header> 5;
  repeated field data :: <secret-key-packet>;
end;

define protocol public-key (container-frame)
  over <openpgp-packet-header> 6;
  repeated field data :: <public-key-packet>;
end;

define protocol secret-subkey (container-frame)
  over <openpgp-packet-header> 7;
  repeated field data :: <secret-key-packet>;
end;

define protocol compressed-data-packet (container-frame)
  over <openpgp-packet-header> 8;
  field compression-algorithm :: <compression-algorithm>;
  field data :: <raw-frame>;
end;

define protocol symmetrically-encrypted-data-packet (container-frame)
  over <openpgp-packet-header> 9;
  field encrypted-data :: <raw-frame>;
end;

define protocol marker-packet (container-frame)
  over <openpgp-packet-header> 10;
  field marker :: <ascii-string> = "PGP";
end;

define protocol literal-data-packet (container-frame)
  over <openpgp-packet-header> 11;
  field data-format :: <unsigned-byte>;
  field file-name-length :: <unsigned-byte>;
  field file-name :: <ascii-string>, length: frame.file-name-length * 8;
  field modification-time :: <unix-time>;
  field data :: <raw-frame>;
end;

define protocol trust-packet (container-frame)
  over <openpgp-packet-header> 12;
end;

define protocol user-id-packet (container-frame)
  over <openpgp-packet-header> 13;
end;

define protocol public-subkey (container-frame)
  over <openpgp-packet-header> 14;
  repeated field data :: <public-key-packet>;
end;

define protocol public-key-packet (container-frame)
  layering field version-number :: <unsigned-byte>;
  field creation-time :: <unix-time>;
end;

define protocol v3-public-key-packet (public-key-packet)
  over <public-key-packet-format> 3;
  field days-valid :: <2byte-big-endian-unsigned-integer>;
  field public-key-algorithm :: <public-key-algorithm>;
  repeated field multi-precision-integers :: <multi-precision-integer>;
end;

define protocol v4-public-key-packet (public-key-packet)
  over <public-key-packet-format> 4;
  field public-key-algorithm :: <public-key-algorithm>;
  repeated field multi-precision-integers :: <multi-precision-integer>;
end;

define protocol secret-key-packet (container-frame)
  field public-key :: <public-key-packet>;
  field string-to-key-usage :: <unsigned-byte>;
  field symmetric-algorithm :: <symmetric-algorithm>;
  field string-to-key-specifier :: <unsigned-byte>; <- length by type
  field initialization-vector :: <8octet-initialization-vector>;
  repeated field encrypted-multi-precision-integers :: <multi-precision-integer>;
  field checksum :: <2byte-big-endian-unsigned-integer>;
end;

define enum-frame signature-type (enum-frame)
  0 => #"binary document";
  1 => #"canonical text document";
  2 => #"standalone signature";
  #x10 => #"generic certification of a user id and public key";
  #x11 => #"persona certification of a user id and public key";
  #x12 => #"casual certification of a user id and public key";
  #x13 => #"positive certification of a user id and public key";
  #x18 => #"subkey binding signature";
  #x1f => #"signature directly on key";
  #x20 => #"key revocation signature";
  #x28 => #"subkey revocation signature";
  #x30 => #"certification revocation signature";
  #x40 => #"timestamp signature";
end;

define enum-frame public-key-algorithm (enum-frame)
  1 => #"rsa encrypt or sign";
  2 => #"rsa encrypt";
  3 => #"rsa sign";
  16 => #"elgamal encrypt";
  17 => #"dsa";
  18 => #"ecc";
  19 => #"ecdsa";
  20 => #"elgamal encrypt or sign";
  21 => #"diffie-hellman";
end;

define enum-frame symmetric-cipher (enum-frame)
  0 => #"unencrypted";
  1 => #"IDEA";
  2 => #"3DES-EDE";
  3 => #"CAST5";
  4 => #"blowfish-128";
  5 => #"SAFER-SK128";
  6 => #"DES-SK";
  7 => #"AES-128";
  8 => #"AES-192";
  9 => #"AES-256";
end;

define enum-frame compression-algorithm (enum-frame)
  0 => #"uncompressed";
  1 => #"zip";
  2 => #"zlib";
end;

define enum-frame hash-algorithm (enum-frame)
  1 => #"md5";
  2 => #"sha1";
  3 => #"ripemd160";
  4 => #"sha256";
  5 => #"md2";
  6 => #"tiger192";
  7 => #"haval-5-160";
end;
