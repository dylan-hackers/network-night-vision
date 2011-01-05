module: tcp
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define protocol tcp-frame (header-frame)
  summary "TCP %s port %= -> %=", flags-summary, source-port, destination-port;
  over <ipv4-frame> 6;
  over <ipv6-frame> 6;
  field source-port :: <2byte-big-endian-unsigned-integer>;
  field destination-port :: <2byte-big-endian-unsigned-integer>;
  field sequence-number :: <big-endian-unsigned-integer-4byte>;
  field acknowledgement-number :: <big-endian-unsigned-integer-4byte>;
  field data-offset :: <4bit-unsigned-integer>,
   fixup: ceiling/(20 + byte-offset(reduce(method(x, y)
                                               frame-size(y) + x
                                           end, 0, frame.options-and-padding)), 4);
  field reserved :: <6bit-unsigned-integer> = 0;
  field urg :: <1bit-unsigned-integer> = 0;
  field ack :: <1bit-unsigned-integer> = 0;
  field psh :: <1bit-unsigned-integer> = 0;
  field rst :: <1bit-unsigned-integer> = 0;
  field syn :: <1bit-unsigned-integer> = 0;
  field fin :: <1bit-unsigned-integer> = 0;
  field window :: <2byte-big-endian-unsigned-integer> = 0;
  field checksum :: <2byte-big-endian-unsigned-integer> = 0;
  field urgent-pointer :: <2byte-big-endian-unsigned-integer> = 0;
  repeated field options-and-padding :: <tcp-option>,
    reached-end?: instance?(frame, <end-of-option>);
  field payload :: <raw-frame> = make(<raw-frame>, data: make(<stretchy-byte-vector-subsequence>)),
    start: frame.data-offset * 4 * 8;
end;

define protocol pseudo-header (container-frame)
  field source-address :: <ipv4-address>;
  field destination-address :: <ipv4-address>;
  field reserved :: <unsigned-byte> = 0;
  field protocol :: <unsigned-byte> = 6;
  field segment-length :: <2byte-big-endian-unsigned-integer>;
  field pseudo-header-data :: <raw-frame>,
    length: frame.segment-length;
end;

define method fixup!(tcp-frame :: <unparsed-tcp-frame>,
                     #next next-method)
  let pseudo-header = make(<pseudo-header>,
                           source-address: tcp-frame.parent.source-address,
                           destination-address: tcp-frame.parent.destination-address,
                           segment-length: tcp-frame.packet.size,
                           pseudo-header-data: make(<raw-frame>, data: tcp-frame.packet));
  let pack = assemble-frame(pseudo-header).packet;
  tcp-frame.checksum := calculate-checksum(pack, pack.size);
  next-method();
end;

define method flags-summary (frame :: <tcp-frame>) => (result :: <string>)
  apply(concatenate,
        map(method(field, id) if (frame.field = 1) id else "" end end,
            list(urg, ack, psh, rst, syn, fin),
            list("U", "A", "P", "R", "S", "F")))
end;

define abstract protocol tcp-option (variably-typed-container-frame)
  layering field tcp-option-type :: <unsigned-byte>;
end;

define protocol end-of-option (tcp-option)
  over <tcp-option> 0;
end;

define protocol no-operation-option (tcp-option)
  over <tcp-option> 1
end;

define abstract protocol tcp-option-with-data (tcp-option)
  length frame.tcp-option-length * 8;
  field tcp-option-length :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame));
end;

define protocol maximum-segment-size-option (tcp-option-with-data)
  over <tcp-option> 2;
  field maximum-segment-size :: <2byte-big-endian-unsigned-integer>;
end;

define protocol window-scale-option (tcp-option-with-data)
  over <tcp-option> 3;
  field shift-count :: <unsigned-byte>;
end;

define protocol tcp-sack-permitted (tcp-option-with-data)
  over <tcp-option> 4;
end;

define protocol tcp-sack-option (tcp-option-with-data)
  over <tcp-option> 5;
  repeated field blocks :: <received-blocks>, reached-end?: #f;
end;

define protocol received-blocks (container-frame)
  field left-edge :: <big-endian-unsigned-integer-4byte>;
  field right-edge :: <big-endian-unsigned-integer-4byte>;
end;

define protocol tcp-echo-option (tcp-option-with-data)
  over <tcp-option> 6;
  field data-to-echo :: <big-endian-unsigned-integer-4byte>;
end;

define protocol tcp-echo-reply-option (tcp-option-with-data)
  over <tcp-option> 7;
  field echoed-data :: <big-endian-unsigned-integer-4byte>;
end;

define protocol tcp-timestamp-option (tcp-option-with-data)
  over <tcp-option> 8;
  field timestamp-value :: <big-endian-unsigned-integer-4byte>;
  field timestamp-echo-reply :: <big-endian-unsigned-integer-4byte>;
end;

define protocol tcp-partial-order-permitted (tcp-option-with-data)
  over <tcp-option> 9;
end;

define protocol tcp-partial-order-service-profile (tcp-option-with-data)
  over <tcp-option> 10;
  field start-flag :: <1bit-unsigned-integer>;
  field end-flag :: <1bit-unsigned-integer>;
  field filler :: <6bit-unsigned-integer> = 0;
end;

define protocol ttcp-connection-count (tcp-option-with-data)
  over <tcp-option> 11;
  field connection-count :: <big-endian-unsigned-integer-4byte>;
end;

define protocol ttcp-connection-count-new (tcp-option-with-data)
  over <tcp-option> 12;
  field connection-count :: <big-endian-unsigned-integer-4byte>;
end;

define protocol ttcp-connection-count-echo (tcp-option-with-data)
  over <tcp-option> 13;
  field connection-count :: <big-endian-unsigned-integer-4byte>;
end;

define protocol tcp-alternate-checksum-request (tcp-option-with-data)
  over <tcp-option> 14;
  field checksum-type :: <unsigned-byte>;
end;

define protocol tcp-alternate-checksum-data (tcp-option-with-data)
  over <tcp-option> 15;
  field checksum-data :: <raw-frame>;
end;

define protocol md5-digest-tcp-option (tcp-option-with-data)
  over <tcp-option> 19;
  field md5-digest :: <raw-frame>, length: 16 * 8;
end;


