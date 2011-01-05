module: dns
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define abstract class <container-frame-with-metadata> (<container-frame>)
  constant slot index-table :: <table> = make(<table>);
  constant slot symbol-table :: <string-table> = make(<string-table>);
end;

define abstract class <decoded-container-frame-with-metadata>
 (<container-frame-with-metadata>, <decoded-container-frame>)
end;

define abstract class <unparsed-container-frame-with-metadata>
 (<container-frame-with-metadata>, <unparsed-container-frame>)
end;

define protocol dns-frame (container-frame-with-metadata)
  over <udp-frame> 53;
  summary "DNS ID=%=, %= questions, %= answers",
    identifier, question-count, answer-count;
  field identifier :: <2byte-big-endian-unsigned-integer> = 2342;
  enum field query-or-response :: <1bit-unsigned-integer> = 0,
    mappings: { 0 <=> #"query",
                1 <=> #"response" };
  enum field opcode :: <4bit-unsigned-integer> = 0,
    mappings: { 0 <=> #"standard query",
                1 <=> #"inverse query",
                2 <=> #"server status request" };
  field authoritative-answer :: <boolean-bit> = #f;
  field truncation :: <boolean-bit> = #f;
  field recursion-desired :: <boolean-bit> = #t;
  field recursion-available :: <boolean-bit> = #f;
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
/*
define method assemble-frame-into
 (frame :: <domain-name>, packet :: <stretchy-byte-vector-subsequence>)
 => (res :: <integer>)
  //assumption: frame.parent.parent is the <dns-frame>!
  let name-table = frame.parent.parent.symbol-table;
  let offset = 0;
  local method encode-fragments (frags :: <collection>) => (res :: <integer>)
          let strings = map(curry(as, <string>), frags);
          let name =  reduce1(method(a, b) concatenate(a, ".", b) end, strings);
          let offset = element(name-table, name, default: #f);
          if (offset)
            assemble-frame-into(make(<label-offset>, offset: offset), packet);
          else
            name-table[name] := packet.start-index + offset;
            offset := offset + assemble-frame-into(frags[0], packet);
            encode-fragments(subsequence(frags, start: 1));
          end;
        end;
  encode-fragments(frame.fragment);
  offset;
end;
*/
define protocol domain-name (container-frame)
  summary "%=", curry(as, <string>);
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
  summary "%= %s", domainname, question-type;
  field domainname :: <domain-name>;
  enum field question-type :: <2byte-big-endian-unsigned-integer> = #"A",
    mappings: { 1  <=> #"A",
                2  <=> #"NS",
                5  <=> #"CNAME",
                6  <=> #"SOA",
                12 <=> #"PTR",
                13 <=> #"HINFO",
                15 <=> #"MX",
                16 <=> #"TXT" };
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
  summary "%= A %=", domainname, ipv4-address;
  over <dns-resource-record> 1;
  field ipv4-address :: <ipv4-address>;
end;

define protocol name-server (dns-resource-record)
  summary "%= NS %=", domainname, ns-name;
  over <dns-resource-record> 2;
  field ns-name :: <domain-name>;
end;

define protocol canonical-name (dns-resource-record)
  summary "%= CNAME %=", domainname, cname; 
  over <dns-resource-record> 5;
  field cname :: <domain-name>;
end;

define protocol start-of-authority (dns-resource-record)
  summary "%= SOA", domainname;
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
  summary "%= PTR %=", domainname, ptr-name;
  over <dns-resource-record> 12;
  field ptr-name :: <domain-name>;
end;

define protocol character-string (container-frame)
  field data-length :: <unsigned-byte>;
  field string-data :: <externally-delimited-string>,
    length: frame.data-length * 8;
end;

define method as (class == <string>, frame :: <character-string>)
 => (res :: <string>)
  as(<string>, frame.string-data);
end;

define protocol host-information (dns-resource-record)
  summary "%= HINFO %=, %=", domainname, cpu, operating-system;
  over <dns-resource-record> 13;
  field cpu :: <character-string>;
  field operating-system :: <character-string>; 
end;

define protocol mail-exchange (dns-resource-record)
  summary "%= MX %= %=", domainname, preference, exchange; 
  over <dns-resource-record> 15;
  field preference :: <2byte-big-endian-unsigned-integer>;
  field exchange :: <domain-name>;
end;

define protocol text-strings (dns-resource-record)
  summary "%= TXT %=", domainname, text-data;
  over <dns-resource-record> 16;
  field text-data :: <character-string>;
end;

