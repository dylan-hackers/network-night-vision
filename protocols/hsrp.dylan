module: hsrp
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

//Cisco Hot Standby Router Protocol (HSRP) RFC 2281 
define abstract binary-data hsrp (variably-typed-container-frame)
  over <udp-frame> 1985;
  field version :: <unsigned-byte> = 0;
  layering field opcode :: <unsigned-byte> = 0;
end;

define abstract binary-data hsrp-rfc2881 (hsrp)
  summary "HSRP v%= (%=)", version, state;
  enum field state :: <unsigned-byte> = 16,
    mappings: { 0 <=> #"Initial",
                1 <=> #"Learn",
                2 <=> #"Listen",
                4 <=> #"Speak",
                8 <=> #"Standby",
                16 <=> #"Active" };
  field hello-time :: <unsigned-byte> = 3;
  field hold-time :: <unsigned-byte> = 10;
  field priority :: <unsigned-byte> = 120;
  field group :: <unsigned-byte> = 1;
  field reserved :: <unsigned-byte> = 0;
  field authentication-data :: <raw-frame> =
    as(<raw-frame>, #(#x63, #x69, #x73, #x63, #x6F, #x00, #x00, #x00)),
    static-length: 8 * 8;
  field virtual-ip :: <ipv4-address>;
end;

define binary-data hsrp-hello (hsrp-rfc2881)
  over <hsrp> 0;
end;

define binary-data hsrp-coup (hsrp-rfc2881)
  over <hsrp> 1;
end;

define binary-data hsrp-resign (hsrp-rfc2881)
  over <hsrp> 2;
end;

define binary-data hsrp-advertisement (hsrp)
  summary "HSRP v%= (%=)", version, state;
  length frame.advertisement-length * 8;
  over <hsrp> 3;
  field hsrp-interface-state :: <2byte-big-endian-unsigned-integer> = 1;
  field advertisement-length :: <2byte-big-endian-unsigned-integer>,
    fixup: byte-offset(frame-size(frame));
  enum field state :: <unsigned-byte> = 16,
    mappings: { 0 <=> #"Initial",
                1 <=> #"Learn",
                2 <=> #"Listen",
                4 <=> #"Speak",
                8 <=> #"Standby",
                16 <=> #"Active" };
  field reserverd1 :: <unsigned-byte>;
  field active-groups :: <2byte-big-endian-unsigned-integer>;
  field passive-groups :: <2byte-big-endian-unsigned-integer>;
  field reserved2 :: <big-endian-unsigned-integer-4byte>;
end;
