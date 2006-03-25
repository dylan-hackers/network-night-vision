module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.


define protocol dns-header (container-frame)
  summary "DNS ID=%=, %= questions, %= answers",
    identifier, question-count, answer-count;
  field identifier :: <2byte-big-endian-unsigned-integer>;
  field query-or-response :: <1bit-unsigned-integer>;
  field opcode :: <4bit-unsigned-integer>;
  field authoritative-answer :: <1bit-unsigned-integer>;
  field truncation :: <1bit-unsigned-integer>;
  field recursion-desired :: <1bit-unsigned-integer>;
  field recursion-available :: <1bit-unsigned-integer>;
  field reserved :: <3bit-unsigned-integer>;
  field response-code :: <4bit-unsigned-integer>;
  field question-count :: <2byte-big-endian-unsigned-integer>;
  field answer-count :: <2byte-big-endian-unsigned-integer>;
  field name-server-count :: <2byte-big-endian-unsigned-integer>;
  field additional-count :: <2byte-big-endian-unsigned-integer>;
  repeated field questions :: <dns-question>,
    count: frame.question-count;
  repeated field answers :: <dns-resource-record>,
    count: frame.answer-count;
  repeated field name-servers :: <dns-resource-record>,
    count: frame.name-server-count;
  repeated field additional-records :: <dns-resource-record>,
    count: frame.additional-count;
end;


define protocol domain-name (container-frame)
  field type-code :: <2bit-unsigned-integer>;
end;

define protocol label-offset (domain-name)
  field offset :: <14bit-unsigned-integer>;
end;

define protocol label (domain-name)
  field length :: <6bit-unsigned-integer>;
  repeated field data :: <unsigned-byte>,
    count: frame.length;
end;

define method parse-frame (frame-type == <domain-name>,
                           packet :: <byte-sequence>,
                           #key start :: <integer> = 0)
 => (value :: <domain-name>, next-unparsed :: <integer>)
  byte-aligned(start);
  let domain-name = make(unparsed-class(<domain-name>),
                         packet: subsequence(packet, start: byte-offset(start)));
  let label-frame-type
    = select (domain-name.type-code)
        0 => <label>;
        3 => <label-offset>;
        otherwise => signal(make(<malformed-packet-error>))
      end;
   parse-frame(label-frame-type, packet, start: start);
end;


define protocol dns-question (container-frame)
  repeated field domainname :: <domain-name>,
    reached-end?: method(frame :: <domain-name>)
                      frame.type-code = 3 | frame.length = 0
                  end;
  field question-type :: <2byte-big-endian-unsigned-integer>;
  field question-class :: <2byte-big-endian-unsigned-integer>;
end;

define protocol dns-resource-record (container-frame)
  repeated field domainname :: <domain-name>,
    reached-end?: method(frame :: <domain-name>)
                      frame.type-code = 3 | frame.length = 0
                  end;
  field rr-type :: <2byte-big-endian-unsigned-integer>;
  field rr-class :: <2byte-big-endian-unsigned-integer>;
  field ttl :: <big-endian-unsigned-integer-4byte>;
  field rdlength :: <2byte-big-endian-unsigned-integer>;
  field rdata :: <raw-frame>, length: frame.rdlength * 8;
end;
