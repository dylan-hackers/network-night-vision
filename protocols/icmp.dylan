module: icmp
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define abstract binary-data icmp-frame (variably-typed-container-frame)
  summary "ICMP type %=", icmp-type;
  over <ipv4-frame> 1;
  over <ipv6-frame> #x3a;
  layering field icmp-type :: <unsigned-byte>;
end;

//XXX!
define constant <ip-frame> = <ipv4-frame>;

define method fixup! (frame :: <unparsed-icmp-frame>,
                      #next next-method)
  frame.checksum := calculate-checksum(frame.packet, frame.packet.size);
  next-method();
end;

define binary-data icmp-destination-unreachable (icmp-frame)
  over <icmp-frame> 3;
  enum field code :: <unsigned-byte>,
    mappings: { 0 <=> #"net unreachable",
                1 <=> #"host unreachable",
                2 <=> #"protocol unreachable",
                3 <=> #"port unreachable",
                4 <=> #"fragmentation needed and df set",
                5 <=> #"source route failed",
                6 <=> #"destination network unknown",
                7 <=> #"destination host unknown",
                8 <=> #"source host isolated",
                9 <=> #"network administratively prohibited",
                10 <=> #"host administratively prohibited",
                11 <=> #"network unreachable for type of service",
                12 <=> #"host unreachable for type of service",
                13 <=> #"communication administratively prohibited",
                14 <=> #"host precedence violation",
                15 <=> #"precedence cutoff in effect" };
  field checksum :: <2byte-big-endian-unsigned-integer> = 0;
  field unused :: <raw-frame>, static-length: 32;
  field original-data :: <ip-frame>;
end;

define binary-data icmp-time-exceeded (icmp-frame)
  over <icmp-frame> 11;
  enum field code :: <unsigned-byte>,
    mappings: { 0 <=> #"time to live exceeded in transit",
                1 <=> #"fragment reassembly time exceeded" };
  field checksum :: <2byte-big-endian-unsigned-integer> = 0;
  field unused :: <raw-frame>, static-length: 32;
  field original-data :: <ip-frame>;
end;

define binary-data icmp-parameter-problem (icmp-frame)
  over <icmp-frame> 12;
  enum field code :: <unsigned-byte>,
    mappings: { 0 <=> #"pointer indicates error" };
  field checksum :: <2byte-big-endian-unsigned-integer> = 0;
  field pointer :: <unsigned-byte>;
  field unused :: <raw-frame>, static-length: 24;
  field original-data :: <ip-frame>;
end;

define binary-data icmp-source-quench (icmp-frame)
  over <icmp-frame> 4;
  field code :: <unsigned-byte> = 0;
  field checksum :: <2byte-big-endian-unsigned-integer> = 0;
  field unused :: <raw-frame>, static-length: 32;
  field original-data :: <ip-frame>;
end;

define binary-data icmp-redirect (icmp-frame)
  over <icmp-frame> 5;
  enum field code :: <unsigned-byte>,
    mappings: { 0 <=> #"redirect for network",
                1 <=> #"redirect for host",
                2 <=> #"redirect for type of service and network",
                3 <=> #"redirect for type of service and host" };
  field checksum :: <2byte-big-endian-unsigned-integer> = 0;
  field gateway-address :: <ipv4-address>;
  field original-data :: <ip-frame>;
end;

define abstract binary-data icmp-echo-message (icmp-frame)
  field code :: <unsigned-byte> = 0;
  field checksum :: <2byte-big-endian-unsigned-integer> = 0;
  field identifier :: <2byte-big-endian-unsigned-integer> = 42;
  field sequence-number :: <2byte-big-endian-unsigned-integer> = 0;
  field icmp-data :: <raw-frame>;
end;

define binary-data icmp-echo-request (icmp-echo-message)
  over <icmp-frame> 8;
end;

define binary-data icmp-echo-reply (icmp-echo-message)
  over <icmp-frame> 0;
end;

define abstract binary-data icmp-timestamp (icmp-frame)
  field code :: <unsigned-byte> = 0;
  field checksum  :: <2byte-big-endian-unsigned-integer> = 0;
  field identifier :: <2byte-big-endian-unsigned-integer> = 42;
  field sequence-number :: <2byte-big-endian-unsigned-integer> = 0;
  field originate-timestamp :: <big-endian-unsigned-integer-4byte>;
  field receive-timestamp :: <big-endian-unsigned-integer-4byte>;
  field transmit-timestamp :: <big-endian-unsigned-integer-4byte>;
end;

define binary-data icmp-timestamp-request (icmp-timestamp)
  over <icmp-frame> 13;
end;

define binary-data icmp-timestamp-reply (icmp-timestamp)
  over <icmp-frame> 14;
end;

define abstract binary-data icmp-information-message (icmp-frame)
  field code :: <unsigned-byte> = 0;
  field checksum  :: <2byte-big-endian-unsigned-integer> = 0;
  field identifier :: <2byte-big-endian-unsigned-integer> = 42;
  field sequence-number :: <2byte-big-endian-unsigned-integer> = 0;
end;

define binary-data icmp-information-request (icmp-information-message)
  over <icmp-frame> 15;
end;

define binary-data icmp-information-reply (icmp-information-message)
  over <icmp-frame> 16;
end;

 
