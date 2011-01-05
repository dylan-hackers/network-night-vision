module: rip
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define abstract protocol rip (variably-typed-container-frame)
  over <udp-frame> 520;
  field command :: <unsigned-byte>;
  layering field version :: <unsigned-byte>;
  field reserved1 :: <2byte-big-endian-unsigned-integer> = 0;
end;
//1 - request
//2 - response
//3 - traceon
//4 - traceoff
//5 - reserved

define protocol rip-v1 (rip)
  over <rip> 1;
  repeated field routes :: <rip-v1-route>, reached-end?: #f;
end;
define protocol rip-v2 (rip)
  over <rip> 2;
  repeated field routes :: <rip-v2-route>, reached-end?: #f;
end;

define protocol rip-v1-route (container-frame)
  field address-family-identifier :: <2byte-big-endian-unsigned-integer>;
  field reserved2 :: <2byte-big-endian-unsigned-integer> = 0;
  field route-ip-address :: <ipv4-address>;
  field reserved3 :: <raw-frame>, static-length: 64;
  field metric :: <big-endian-unsigned-integer-4byte>;
end;

define protocol rip-v2-route (container-frame)
  field address-family-identifier :: <2byte-big-endian-unsigned-integer>;
  field route-tag :: <2byte-big-endian-unsigned-integer> = 0;
  field route-ip-address :: <ipv4-address>;
  field subnet-mask :: <ipv4-address>;
  field next-hop :: <ipv4-address>;
  field metric :: <big-endian-unsigned-integer-4byte>
end;

define protocol rip-v2-authentication (container-frame)
  field authentication-id :: <2byte-big-endian-unsigned-integer> = #xffff;
  field authentication-type :: <2byte-big-endian-unsigned-integer>;
  field authentication-value :: <raw-frame>, static-length: 16 * 8;
end;

define protocol rip-ng (rip)
  over <udp-frame> 521;
  repeated field routes :: <rip-ng-route>, reached-end?: #f;
end;

define protocol rip-ng-route (container-frame)
  field ipv6-prefix :: <raw-frame>, static-length: 128; //<ipv6-address>;
  field route-tag :: <2byte-big-endian-unsigned-integer>;
  field prefix-length :: <unsigned-byte>;
  field metric :: <unsigned-byte>;
end;


