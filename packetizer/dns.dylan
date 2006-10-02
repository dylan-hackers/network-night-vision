module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.


define protocol dns-frame (container-frame)
  summary "DNS ID=%=, %= questions, %= answers",
    identifier, question-count, answer-count;
  field identifier :: <2byte-big-endian-unsigned-integer>;
  field query-or-response :: <1bit-unsigned-integer> = 1;
  field opcode :: <4bit-unsigned-integer>;
  field authoritative-answer :: <1bit-unsigned-integer>;
  field truncation :: <1bit-unsigned-integer> = 0;
  field recursion-desired :: <1bit-unsigned-integer> = 1;
  field recursion-available :: <1bit-unsigned-integer> = 0;
  field reserved :: <3bit-unsigned-integer> = 0;
  field response-code :: <4bit-unsigned-integer>;
  field question-count :: <2byte-big-endian-unsigned-integer>,
    fixup: frame.questions.size;
  field answer-count :: <2byte-big-endian-unsigned-integer>,
    fixup: frame.answers.size;
  field name-server-count :: <2byte-big-endian-unsigned-integer>,
    fixup: frame.name-servers.size;
  field additional-count :: <2byte-big-endian-unsigned-integer>,
    fixup: frame.additional-records.size;
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
  repeated field fragment :: <domain-name-fragment>,
    reached-end?: method(frame :: <domain-name-fragment>)
                      frame.type-code = 3 | frame.length = 0
                  end;
end;

define method as (class == <string>, domain-name :: <domain-name>)
 => (res :: <string>)
  let strings = map(curry(as, <string>), domain-name.fragment);
  reduce1(method(a, b) concatenate(a, ".",  b) end, strings);
end;

define protocol domain-name-fragment (container-frame)
  field type-code :: <2bit-unsigned-integer>;
end;

define protocol label-offset (domain-name-fragment)
  field offset :: <14bit-unsigned-integer>;
end;

define function find-label (label-offset :: <label-offset>)
 => (label :: false-or(<domain-name>))
  local method find-dns-frame (frame :: <frame>)
          if (instance?(frame, <dns-frame>))
            frame;
          elseif (frame.parent)
            find-dns-frame(frame.parent);
          end;
        end;
  let dns-frame = find-dns-frame(label-offset);
  dns-frame
    & parse-frame(<domain-name>,
                  assemble-frame(dns-frame),
                  start: label-offset.offset * 8,
                  parent: dns-frame);
end;

define method as (class == <string>, label-offset :: <label-offset>)
 => (res :: <string>)
  as(<string>, find-label(label-offset));
end;

define class <externally-delimited-string> (<variable-size-byte-vector>)
end;

define method as (class == <string>, frame :: <externally-delimited-string>)
 => (res :: <string>)
  let res = make(<string>, size: byte-offset(frame-size(frame)));
  copy-bytes(frame.data, 0, res, 0, byte-offset(frame-size(frame)));
  res;
end;

define protocol label (domain-name-fragment)
  field length :: <6bit-unsigned-integer>;
  field raw-data :: <externally-delimited-string>,
    length: frame.length * 8;
end;

define method as (class == <string>, label :: <label>)
 => (res :: <string>)
  as(<string>, label.raw-data);
end;  

define method parse-frame (frame-type == <domain-name-fragment>,
                           packet :: <byte-sequence>,
                           #key start :: <integer> = 0,
                           parent :: false-or(<container-frame>) = #f)
 => (value :: <domain-name-fragment>, next-unparsed :: false-or(<integer>))
  byte-aligned(start);
  let domain-name = make(unparsed-class(<domain-name-fragment>),
                         packet: subsequence(packet, start: byte-offset(start)));
  let label-frame-type
    = select (domain-name.type-code)
        0 => <label>;
        3 => <label-offset>;
        otherwise => signal(make(<malformed-packet-error>))
      end;
  parse-frame(label-frame-type, packet, start: start, parent: parent);
end;


define protocol dns-question (container-frame)
  field domainname :: <domain-name>;
  field question-type :: <2byte-big-endian-unsigned-integer>;
  field question-class :: <2byte-big-endian-unsigned-integer>;
end;

define protocol dns-resource-record (container-frame)
  field domainname :: <domain-name>;
  field rr-type :: <2byte-big-endian-unsigned-integer>;
  field rr-class :: <2byte-big-endian-unsigned-integer>;
  field ttl :: <big-endian-unsigned-integer-4byte>;
  field rdlength :: <2byte-big-endian-unsigned-integer>;
  variably-typed-field rdata,
    type-function: select (frame.rr-type)
                     1 => <a-host-address>;
                     2 => <name-server>;
                     5 => <canonical-name>;
                     6 => <start-of-authority>;
                     12 => <domain-name-pointer>;
                     13 => <host-information>;
                     15 => <mail-exchange>;
                     16 => <text-strings>;
                     otherwise => <raw-frame>;
                   end,
    length: frame.rdlength * 8;
end;

define protocol a-host-address (container-frame)
  field ipv4-address :: <ipv4-address>;
end;

define protocol name-server (container-frame)
  field ns-name :: <domain-name>;
end;

define protocol canonical-name (container-frame)
  field cname :: <domain-name>;
end;

define protocol start-of-authority (container-frame)
  field nameserver :: <domain-name>;
  field hostmaster :: <domain-name>;
  field serial :: <big-endian-unsigned-integer-4byte>;
  field refresh :: <big-endian-unsigned-integer-4byte>;
  field retry :: <big-endian-unsigned-integer-4byte>;
  field expire :: <big-endian-unsigned-integer-4byte>;
  field minimum :: <big-endian-unsigned-integer-4byte>;
end;

define protocol domain-name-pointer (container-frame)
  field ptr-name :: <domain-name>;
end;

define protocol character-string (container-frame)
  field length :: <unsigned-byte>;
  field data :: <externally-delimited-string>,
    length: frame.length * 8;
end;

define protocol host-information (container-frame)
  field cpu :: <character-string>;
  field operating-system :: <character-string>; 
end;

define method as (class == <string>, frame :: <character-string>)
 => (res :: <string>)
  as(<string>, frame.data);
end;

define protocol mail-exchange (container-frame)
  field preference :: <2byte-big-endian-unsigned-integer>;
  field exchange :: <domain-name>;
end;

define protocol text-strings (container-frame)
  field data :: <character-string>;
end;

