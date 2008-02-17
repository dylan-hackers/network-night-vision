module: pcap
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

// from pcap-bpf.h
define constant $DLT-EN10MB = 1;
define constant $DLT-C-HDLC = 104;
define constant $DLT-PRISM-HEADER = 119;
define constant $DLT-80211-BSD-RADIO = 127;

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


define protocol unix-time-value (container-frame)
  field seconds :: <little-endian-unsigned-integer-4byte>;
  field microseconds :: <little-endian-unsigned-integer-4byte>;
end;


define method decode-unix-time (unix-time :: <unix-time-value>)
 => (res :: <date>)
 let secs = byte-vector-to-float-le(unix-time.seconds.data);
 let (days, rem0) = floor/(secs, 86400);
 let (hours, rem1) = floor/(rem0, 3600);
 let (minutes, seconds) = floor/(rem1, 60);
 encode-day/time-duration(days, hours, minutes, round(seconds),
                          floor/(byte-vector-to-float-le(unix-time.microseconds.data), 1))
  + make(<date>, year: 1970, month: 1, day: 1)
end;

define method make-unix-time (dur :: <day/time-duration>)
  => (res :: <unix-time-value>)
  let (days, hours, minutes, seconds, microseconds) = decode-duration(dur);
  let secs = ((as(<double-float>, days) * 24 + hours) * 60 + minutes) * 60 + seconds;
  make(<unix-time-value>,
       seconds: little-endian-unsigned-integer-4byte(float-to-byte-vector-le(secs)),
       microseconds: little-endian-unsigned-integer-4byte(float-to-byte-vector-le(as(<double-float>, microseconds))));
end;

define protocol pcap-packet (header-frame)
  field timestamp :: <unix-time-value>
    = make-unix-time(current-date() - make(<date>, year: 1970, month: 1, day: 1));
  field capture-length :: <3byte-little-endian-unsigned-integer>,
   fixup: size(frame.payload.packet);
  field last-capture-length :: <unsigned-byte> = 0;
  field packet-length :: <3byte-little-endian-unsigned-integer>,
   fixup: size(frame.payload.packet);
  field last-packet-length :: <unsigned-byte> = 0;
  variably-typed-field payload,
    type-function: select (frame.parent.header.linktype)
                     $DLT-EN10MB => <ethernet-frame>;
                     $DLT-C-HDLC => <cisco-hdlc-frame>;
                     $DLT-PRISM-HEADER => <prism2-frame>;
                     $DLT-80211-BSD-RADIO => <bsd-80211-radio-frame>; 
                     otherwise => <raw-frame>;
                   end,
    length: frame.capture-length * 8;
end;

define protocol pcap-file (container-frame)
  field header :: <pcap-file-header>;
  repeated field packets :: <pcap-packet>,
    reached-end?: #f;
end;

//linktype => payload-type mapping

//version <2.3 => capture-length and packet-length are swapped
//543 (DG/UX) => swapped
