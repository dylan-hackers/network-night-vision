module: ospf
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define protocol ospf-v2 (container-frame)
  field version :: <unsigned-byte> = 2;
  layering field type :: <unsigned-byte>;
  field packet-length :: <2byte-big-endian-unsigned-integer>;
  field router-id :: <big-endian-unsigned-integer-4byte>;
  field area-id :: <big-endian-unsigned-integer-4byte>;
  field checksum :: <2byte-big-endian-unsigned-integer>;
  field authentication-scheme :: <2byte-big-endian-unsigned-integer>;
  field authentication :: <raw-frame>, static-length: 8 * 8;
end;

define protocol ospf-v2-hello (ospf-v2)
  over <ospf-v3> 1;
  field network-mask :: <ipv4-address>;
  field hello-interval :: <2byte-big-endian-unsigned-integer>;
  field options :: <unsigned-byte>;
  field router-priority :: <unsigned-byte>;
  field dead-interval :: <big-endian-unsigned-integer-4byte>;
  field designated-router :: <ipv4-address>;
  field backup-designated-router :: <ipv4-address>;
  repeated field neighbor :: <ipv4-address>, reached-end?: #f;
end;

define protocol ospf-v2-database-description (ospf-v2)
  over <ospf-v2> 2;
  field reserved1 :: <2byte-big-endian-unsigned-integer> = 0;
  field options :: <unsigned-byte>;
  field reserved2 :: <5bit-unsigned-integer>;
  field init-bit :: <1bit-unsigned-integer>;
  field more-bit :: <1bit-unsigned-integer>;
  field master-slave-bit :: <1bit-unsigned-integer>;
  field database-description-sequence-number :: <big-endian-unsigned-integer-4byte>;
  field link-state-advertisment;
end;


