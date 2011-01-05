module: bittorrent
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

//incomplete from http://xbtt.sourceforge.net/udp_tracker_protocol.html
define protocol bittorrent-announce (container-frame)
  field connection-id :: <raw-frame> =
    as(<raw-frame>,
       #(#x0, #x0, #x04, #x17, #x27, #x10, #x19, #x80)),
    static-length: 8 * 8;
  field action :: <big-endian-unsigned-integer-4byte> = big-endian-unsigned-integer-4byte(#(#x0, #x0, #x0, #x1));
  field transaction-id :: <big-endian-unsigned-integer-4byte> = big-endian-unsigned-integer-4byte(#(0, 0, 23, 42));
  field info-hash :: <raw-frame> =
    as(<raw-frame>,
       #(#xF7, #x90, #xBA, #x87, #x8D, #x9F, #xF7, #xC3, #x02, #x45,
         #x62, #x6B, #xA2, #x8E, #x8C, #x6D, #x89, #x70, #x50, #xD9)),
    static-length: 20 * 8;
  field peer-id :: <raw-frame> = read-frame(<raw-frame>, "fnord!"),
    static-length: 20 * 8;
  field downloaded :: <raw-frame> = $empty-raw-frame, static-length: 8 * 8;
  field left :: <raw-frame> = $empty-raw-frame, static-length: 8 * 8;
  field uploaded :: <raw-frame> = $empty-raw-frame, static-length: 8 * 8;
  field event :: <big-endian-unsigned-integer-4byte> = 
    big-endian-unsigned-integer-4byte(#(0, 0, 0, 3));
  field ip-address :: <ipv4-address> = ipv4-address("217.13.206.133");
  field key :: <big-endian-unsigned-integer-4byte> =
    big-endian-unsigned-integer-4byte(#(0, 0, 23, 42));
  field num-want :: <big-endian-unsigned-integer-4byte> = 
    big-endian-unsigned-integer-4byte(#(0, 0, 0, 10));
  field port :: <2byte-big-endian-unsigned-integer> = 6887;
end;

define protocol bittorrent-announce-output (container-frame)
  over <udp-frame> 6969;
  field action :: <big-endian-unsigned-integer-4byte>;
  field transaction-id :: <big-endian-unsigned-integer-4byte>;
  field interval :: <big-endian-unsigned-integer-4byte>;
  field leechers :: <big-endian-unsigned-integer-4byte>;
  field seeders :: <big-endian-unsigned-integer-4byte>;
  repeated field peers :: <ip-and-port>,
    reached-end?: #f;
end;

define protocol ip-and-port (container-frame)
  field ip :: <ipv4-address>;
  field port :: <2byte-big-endian-unsigned-integer>;
end;