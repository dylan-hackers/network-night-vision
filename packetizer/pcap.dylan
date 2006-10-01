module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

// from pcap-bpf.h
define constant $DLT-EN10MB = 1;
define constant $DLT-PRISM-HEADER = 119;

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

define function int-to-byte-vector (int :: <integer>) => (res :: <byte-vector>)
  let res = make(<byte-vector>, size: 4);
  for (i from 0 below 4)
    res[i] := logand(#xff, ash(int, - i * 8));
  end;
  res;
end;

define function float-to-byte-vector (float :: <float>) => (res :: <byte-vector>)
  let res = make(<byte-vector>, size: 4, fill: 0);
  let r = float;
  for (i from 0 below 4)
    let (this, remainder) = floor/(r, 256);
    r := this;
    res[i] := floor(remainder);
  end;
  res;
end;

define protocol unix-time-value (container-frame)
  field seconds :: <little-endian-unsigned-integer-4byte>;
  field microseconds :: <little-endian-unsigned-integer-4byte>;
end;

define function byte-vector-to-float (bv :: <stretchy-byte-vector-subsequence>) => (res :: <float>)
  let res = 0.0d0;
  for (ele in reverse(bv))
    res := ele + 256 * res;
  end;
  res;
end;

define function byte-vector-to-int (bv :: <stretchy-byte-vector-subsequence>) => (res :: <integer>)
  let res = 0;
  let first? = #t;
  for (ele in reverse(bv))
    if (first?)
      first? := #f
    else
      res := ele + 256 * res;
    end;
  end;
  res;
end;

define method decode-unix-time (unix-time :: <unix-time-value>)
 => (res :: <date>)
 let secs = byte-vector-to-float(unix-time.seconds.data);
 let (days, rem0) = floor/(secs, 86400);
 let (hours, rem1) = floor/(rem0, 3600);
 let (minutes, seconds) = floor/(rem1, 60);
 encode-day/time-duration(days, hours, minutes, round(seconds),
                          byte-vector-to-int(unix-time.microseconds.data))
  + make(<date>, year: 1970, month: 1, day: 1)
end;

define method make-unix-time (dur :: <day/time-duration>)
  => (res :: <unix-time-value>)
  let (days, hours, minutes, seconds, microseconds) = decode-duration(dur);
  let secs = ((as(<double-float>, days) * 24 + hours) * 60 + minutes) * 60 + seconds;
  make(<unix-time-value>,
       seconds: little-endian-unsigned-integer-4byte(float-to-byte-vector(secs)),
       microseconds: little-endian-unsigned-integer-4byte(int-to-byte-vector(microseconds)));
end;

define protocol pcap-packet (header-frame)
  field timestamp :: <unix-time-value>
    = make-unix-time(current-date() - make(<date>, year: 1970, month: 1, day: 1));
  field capture-length :: <3byte-little-endian-unsigned-integer>,
   fixup: byte-offset(frame-size(frame.payload));
  field last-capture-length :: <unsigned-byte> = 0;
  field packet-length :: <3byte-little-endian-unsigned-integer>,
   fixup: byte-offset(frame-size(frame.payload));
  field last-packet-length :: <unsigned-byte> = 0;
  variably-typed-field payload,
    type-function: select (frame.parent.header.linktype)
                     $DLT-EN10MB => <ethernet-frame>;
                     $DLT-PRISM-HEADER => <prism2-frame>;
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
