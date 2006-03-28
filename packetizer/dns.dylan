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
  repeated field data :: <domain-name-fragment>,
    reached-end?: method(frame :: <domain-name-fragment>)
                      frame.type-code = 3 | frame.length = 0
                  end;
end;

define method as (class == <string>, domain-name :: <domain-name>)
 => (res :: <string>)
  let strings = map(curry(as, <string>), domain-name.data);
  reduce1(method(a, b) concatenate(a, ".",  b) end, strings);
end;

define protocol domain-name-fragment (container-frame)
  field type-code :: <2bit-unsigned-integer>;
end;

define protocol label-offset (domain-name-fragment)
  field offset :: <14bit-unsigned-integer>;
end;

define function find-label (label-offset :: <label-offset>)
 => (label :: false-or(<label>))
  local method find-dns-frame (frame :: <frame>)
          if (instance?(frame, <dns-header>))
            frame;
          elseif (frame.parent)
            find-dns-frame(frame.parent);
          end;
        end;
  let frame = find-dns-frame(label-offset);
  any?(method(x) x.start-offset = label-offset.offset end,
       sorted-frame-fields(frame));
end;

define method as (class == <string>, label-offset :: <label-offset>)
 => (res :: <string>)
  as(<string>, find-label(label-offset));
end;

define protocol label (domain-name-fragment)
  field length :: <6bit-unsigned-integer>;
  repeated field data :: <unsigned-byte>,
    count: frame.length;
end;

define method as (class == <string>, label :: <label>)
 => (res :: <string>)
  let res = make(<string>, size: label.length);
  copy-bytes(label.data, 0, res, 0, label.length);
  res;
end;  

define method parse-frame (frame-type == <domain-name-fragment>,
                           packet :: <byte-sequence>,
                           #key start :: <integer> = 0,
                           parent :: false-or(<container-frame>) = #f)
 => (value :: <domain-name-fragment>, next-unparsed :: <integer>)
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
                     //13 => <host-information>;
                     15 => <mail-exchange>;
                     //16 => <text-strings>;
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
/*
define protocol host-information (container-frame)
  field cpu :: <character-string>;
  field operating-system :: <character-string>; 
end;

define protocol character-string (container-frame)
  field length :: <unsinged-byte>;
  field data :: <string>, length: frame.length;
end;
*/

define protocol mail-exchange (container-frame)
  field preference :: <2byte-big-endian-unsigned-integer>;
  field exchange :: <domain-name>;
end;

/*
define protocol text-strings (container-frame)
  repeated field data :: <character-string>;
end;
*/
