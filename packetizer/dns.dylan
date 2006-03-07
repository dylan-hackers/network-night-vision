module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.


define protocol dns-header (<container-frame>)
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


define protocol label (<container-frame>)
  field length :: <unsigned-byte>;
  repeated field data :: <unsigned-byte>,
    count: frame.length;
end;

define protocol dns-question (<container-frame>)
  repeated field domainname :: <label>,
    reached-end?: method(frame :: <label>)
                      frame.length = 0
                  end;
  field question-type :: <2byte-big-endian-unsigned-integer>;
  field question-class :: <2byte-big-endian-unsigned-integer>;
end;
