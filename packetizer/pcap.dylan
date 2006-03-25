module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

//FIXME
define n-byte-vector(little-endian-unsigned-integer-4byte, 4) end;

define protocol pcap-file-header (container-frame)
  field magic :: <little-endian-unsigned-integer-4byte>
   = little-endian-unsigned-integer-4byte(#(#xd4, #xc3, #xb2, #xa1));
  field major-version :: <2byte-little-endian-unsigned-integer> = 2;
  field minor-version :: <2byte-little-endian-unsigned-integer> = 4;
  field timezone-offset :: <little-endian-unsigned-integer-4byte>
   = little-endian-unsigned-integer-4byte(#(#x00, #x00, #x00, #x00));
  field sigfigs :: <little-endian-unsigned-integer-4byte>
   = little-endian-unsigned-integer-4byte(#(#x00, #x00, #x00, #x00));
  field snap-length :: <3byte-little-endian-unsigned-integer> = 1548;
  field last-snap :: <unsigned-byte> = 0;
  field linktype :: <3byte-little-endian-unsigned-integer> = 1;
  field last-linktype :: <unsigned-byte> = 0;
end;

define function get-seconds () => (seconds :: <collection>)
  let (year, month, day, hours, minutes, seconds,
       day-of-week, time-zone-offset) = decode-date(current-date());
  let res = make(<byte-vector>, size: 4);
  for (ele in res,
       i from 0)
    res[i] := logand(#xff, ash(seconds, - i * 8));
  end;
  res;
end;

define protocol unix-time-value (container-frame)
  field seconds :: <little-endian-unsigned-integer-4byte>
   = little-endian-unsigned-integer-4byte(get-seconds());
  field microseconds :: <little-endian-unsigned-integer-4byte>
   = little-endian-unsigned-integer-4byte(#(#x00, #x00, #x00, #x00));
end;

define protocol pcap-packet (header-frame)
  field timestamp :: <unix-time-value> = make(<unix-time-value>);
  field capture-length :: <3byte-little-endian-unsigned-integer>,
   fixup: byte-offset(frame-size(frame.payload));
  field last-capture-length :: <unsigned-byte> = 0;
  field packet-length :: <3byte-little-endian-unsigned-integer>,
   fixup: byte-offset(frame-size(frame.payload));
  field last-packet-length :: <unsigned-byte> = 0;
  variably-typed-field payload,
    type-function: select (frame.parent.header.linktype)
                     1 => <ethernet-frame>;
                     otherwise => <raw-frame>;
                   end,
    length: frame.capture-length * 8;
end;

define protocol pcap-file (container-frame)
  field header :: <pcap-file-header>;
  repeated field packets :: <pcap-packet>,
    reached-end?: method(v :: <pcap-packet>)
                      #f
                  end;
end;

//linktype => payload-type mapping

//version <2.3 => capture-length and packet-length are swapped
//543 (DG/UX) => swapped
