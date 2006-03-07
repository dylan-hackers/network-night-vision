module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

//FIXME
define n-byte-vector(<4byte-little-endian-unsigned-integer>, 4) end;

define protocol pcap-file-header (<container-frame>)
  field magic :: <4byte-little-endian-unsigned-integer>;
  field major-version :: <2byte-little-endian-unsigned-integer>;
  field minor-version :: <2byte-little-endian-unsigned-integer>;
  field timezone-offset :: <4byte-little-endian-unsigned-integer>;
  field sigfigs :: <4byte-little-endian-unsigned-integer>;
  field snap-length :: <4byte-little-endian-unsigned-integer>;
  field linktype :: <3byte-little-endian-unsigned-integer>;
  field last-linktype :: <unsigned-byte>;
end;

define protocol unix-time-value (<container-frame>)
  field seconds :: <4byte-little-endian-unsigned-integer>; 
  field microseconds :: <4byte-little-endian-unsigned-integer>;
end;

define protocol pcap-packet (<container-frame>)
  field timestamp :: <unix-time-value>;
  field capture-length :: <3byte-little-endian-unsigned-integer>;
  field last-capture-length :: <unsigned-byte>;
  field packet-length :: <4byte-little-endian-unsigned-integer>;
  variably-typed-field payload,
    type-function: select (frame.parent.header.linktype)
                     1 => <ethernet-frame>;
                     otherwise => <raw-frame>;
                   end,
    length: frame.capture-length * 8;
end;

define protocol pcap-file (<container-frame>)
  field header :: <pcap-file-header>;
  repeated field packets :: <pcap-packet>,
    reached-end?: method(v :: <pcap-packet>)
                      #f
                  end;
end;

//linktype => payload-type mapping

//version <2.3 => capture-length and packet-length are swapped
//543 (DG/UX) => swapped
