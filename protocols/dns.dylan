module: dns
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define protocol dns-frame (container-frame)
  over <udp-frame> 53;
  summary "DNS ID=%=, %= questions, %= answers",
    identifier, question-count, answer-count;
  field identifier :: <2byte-big-endian-unsigned-integer> = 2342;
  field query-or-response :: <1bit-unsigned-integer> = 0;
  field opcode :: <4bit-unsigned-integer> = 0;
  field authoritative-answer :: <1bit-unsigned-integer> = 0;
  field truncation :: <1bit-unsigned-integer> = 0;
  field recursion-desired :: <1bit-unsigned-integer> = 1;
  field recursion-available :: <1bit-unsigned-integer> = 0;
  field reserved :: <3bit-unsigned-integer> = 0;
  field response-code :: <4bit-unsigned-integer> = 0;
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
  summary "%s", curry(as, <string>);
  repeated field fragment :: <domain-name-fragment>,
    reached-end?: frame.type-code = 3 | frame.data-length = 0;
end;

define method as (class == <string>, domain-name :: <domain-name>)
 => (res :: <string>)
  let strings = map(curry(as, <string>), domain-name.fragment);
  reduce1(method(a, b) concatenate(a, ".",  b) end, strings);
end;

define method as (class == <domain-name>, string :: <string>)
 => (res :: <domain-name>)
  let labels = split(string, '.');
  labels := concatenate(labels, #(""));
  make(<domain-name>, fragment: map(curry(as, <label>), labels));
end;

define abstract protocol domain-name-fragment (variably-typed-container-frame)
  layering field type-code :: <2bit-unsigned-integer> = 0;
end;

define protocol label-offset (domain-name-fragment)
  over <domain-name-fragment> 3;
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
  if (dns-frame)
    let dns-frame-size = dns-frame.packet.size;
    if (label-offset.offset < dns-frame-size)
      parse-frame(<domain-name>,
                  subsequence(dns-frame.packet, start: label-offset.offset * 8),
                  parent: label-offset.parent)
    end;
  end;
end;

define method as (class == <string>, label-offset :: <label-offset>)
 => (res :: <string>)
  let label = find-label(label-offset);
  if (label)
    as(<string>, label);
  else
    format-out("couldn't find label at %d\n", label-offset.offset);
    integer-to-string(label-offset.offset)
  end;
end;

define protocol label (domain-name-fragment)
  over <domain-name-fragment> 0;
  field data-length :: <6bit-unsigned-integer>,
    fixup: frame.raw-data.frame-size.byte-offset;
  field raw-data :: <externally-delimited-string>,
    length: frame.data-length * 8;
end;

define method as (class == <string>, label :: <label>)
 => (res :: <string>)
  as(<string>, label.raw-data);
end;  

define method as (class == <label>, string :: <string>)
 => (res :: <label>)
  make(<label>, raw-data: as(<externally-delimited-string>, string))
end;


define protocol dns-question (container-frame)
  field domainname :: <domain-name>;
  field question-type :: <2byte-big-endian-unsigned-integer>;
  field question-class :: <2byte-big-endian-unsigned-integer> = 1;
end;

define abstract protocol dns-resource-record (variably-typed-container-frame)
  length frame.rdlength * 8 + 80 + frame.domainname.frame-size;
  field domainname :: <domain-name>;
  layering field rr-type :: <2byte-big-endian-unsigned-integer>;
  field rr-class :: <2byte-big-endian-unsigned-integer> = 1;
  field ttl :: <big-endian-unsigned-integer-4byte>;
  field rdlength :: <2byte-big-endian-unsigned-integer>,
    fixup: frame.frame-size.byte-offset - 10 - frame.domainname.frame-size.byte-offset;
end;

define protocol a-host-address (dns-resource-record)
  over <dns-resource-record> 1;
  field ipv4-address :: <ipv4-address>;
end;

define protocol name-server (dns-resource-record)
  over <dns-resource-record> 2;
  field ns-name :: <domain-name>;
end;

define protocol canonical-name (dns-resource-record)
  over <dns-resource-record> 5;
  field cname :: <domain-name>;
end;

define protocol start-of-authority (dns-resource-record)
  over <dns-resource-record> 6;
  field nameserver :: <domain-name>;
  field hostmaster :: <domain-name>;
  field serial :: <big-endian-unsigned-integer-4byte>;
  field refresh :: <big-endian-unsigned-integer-4byte>;
  field retry :: <big-endian-unsigned-integer-4byte>;
  field expire :: <big-endian-unsigned-integer-4byte>;
  field minimum :: <big-endian-unsigned-integer-4byte>;
end;

define protocol domain-name-pointer (dns-resource-record)
  over <dns-resource-record> 12;
  field ptr-name :: <domain-name>;
end;

define protocol character-string (container-frame)
  field data-length :: <unsigned-byte>;
  field string-data :: <externally-delimited-string>,
    length: frame.data-length * 8;
end;

define protocol host-information (dns-resource-record)
  over <dns-resource-record> 13;
  field cpu :: <character-string>;
  field operating-system :: <character-string>; 
end;

define method as (class == <string>, frame :: <character-string>)
 => (res :: <string>)
  as(<string>, frame.string-data);
end;

define protocol mail-exchange (dns-resource-record)
  over <dns-resource-record> 15;
  field preference :: <2byte-big-endian-unsigned-integer>;
  field exchange :: <domain-name>;
end;

define protocol text-strings (dns-resource-record)
  over <dns-resource-record> 16;
  field text-data :: <character-string>;
end;

