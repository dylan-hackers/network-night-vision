module: dns
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

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

define generic domain-names (q-or-rr :: type-union(<dns-question>, <dns-resource-record>)) => (l :: <list>);


define method find-offset (search :: <frame>, current :: <container-frame>) => (offset :: <integer>)
  //format-out("find-offset, searching for %= in %=\n", search, current);
  //force-output(*standard-output*);
  let ff = find-frame-field(current, search);
  let off1 =
    if (instance?(current, <dns-frame>))
      format-out("searching for offset where c = t %d\n", ff.start-offset);
      force-output(*standard-output*);
      0
    else
      format-out("recursing to parent, off is %d\n", ff.start-offset);
      force-output(*standard-output*);
      find-offset(current, current.parent);
    end;
  let off2 =
    if (instance?(ff, <rep-frame-field>))
      ff.start-offset + ff.parent-frame-field.start-offset
    else
      ff.start-offset
    end;
  off1 + off2
end;

define method fixup!(dns-frame :: <unparsed-dns-frame>,
                     #next next-method)
  format-out("fixup: %=\n", dns-frame);
  force-output(*standard-output*);
  let names = make(<string-table>);
  local method collect-and-maybe-replace (dn :: <domain-name>)
          let frags = #();
          block(done)
            format-out("I'm collecting domainname %s\n", as(<string>, dn));
            force-output(*standard-output*);
            let off-till-dn = byte-offset(find-offset(dn, dn.parent));
            format-out("collecting (%d): %s\n", off-till-dn, as(<string>, dn));
            force-output(*standard-output*);
            for (label in dn.fragment,
                 i from 0,
                 ff in dn.concrete-frame-fields[0].frame-field-list)
              if (as(<string>, label) == "")
                frags := pair(label, frags);
              else
                let strings = map(curry(as, <string>), copy-sequence(dn.fragment, start: i));
                let string = reduce1(method(a, b) concatenate(a, ".",  b) end, strings);
                format-out("starting with %s\n", string);
                force-output(*standard-output*);
                if (element(names, string, default: #f))
                  format-out("using offset for %s: %d\n", string, names[string]);
                  force-output(*standard-output*);
                  let lo = make(<label-offset>, offset: names[string], parent: label.parent);
                  format-out("created lo %=\n", lo);
                  force-output(*standard-output*);
                  frags := pair(lo, frags);
                  let off = byte-offset(start-offset(ff)) + off-till-dn;
                  let bv = assemble-frame(lo).packet;
                  format-out("replacing (at %d) %d with %d %d\n", off, dns-frame.packet[off], bv[0], bv[1]);
                  let oldlen = byte-offset(ff.parent-frame-field.length - ff.start-offset);
                  format-out("oldlen would have been %d\n", oldlen);
                  force-output(*standard-output*);
                  dns-frame.packet[off] := bv[0];
                  dns-frame.packet[off + 1] := bv[1];
                  dns-frame.packet :=
                    make(<stretchy-vector-subsequence>,
                         data: as(<stretchy-byte-vector>,
                                  concatenate(copy-sequence(dns-frame.packet, end: off + 2),
                                              copy-sequence(dns-frame.packet, start: off + oldlen))));
                  format-out("pack %=\n", copy-sequence(dns-frame.packet, start: off - 3, end: off + 4));
                  format-out("dne\n"); force-output(*standard-output*);
                  //fixup assembled subsequence - shrink it
                  //need to fixup frame fields...
                  done();
                else
                  let off = byte-offset(start-offset(ff)) + off-till-dn;
                  format-out("inserting offset for %s at %d\n", string, off);
                  force-output(*standard-output*);
                  names[string] := off;
                  frags := pair(label, frags);
                end if;
              end if;
            end for;
          end block;
          dn.fragment := reverse!(frags);
          //let res = make(<domain-name>, fragment: reverse!(frags));
          //format-out("result is %s\n", as(<string>, dn));
          //force-output(*standard-output*);
          //res;
          //dn;
        end method;
  local method maybe-replace (dns :: type-union(<dns-question>, <dns-resource-record>))
          let dnss = domain-names(dns);
          map(method (x)
                collect-and-maybe-replace(x.head(dns));
                //format-out("replacing with %= (using x.tail %= and dns %=)\n", as(<string>, replacement), x.tail, dns);
                //force-output(*standard-output*);
                //let rpl = assemble-frame!(replacement).packet;
                //let ff = get-frame-field(0, replacement);
                //x.tail(replacement, dns);
              end, domain-names(dns));
        end method;
  map(maybe-replace, dns-frame.questions);
  format-out("now answers\n");
  force-output(*standard-output*);
  map(maybe-replace, dns-frame.answers);
  format-out("now name-servers\n");
  force-output(*standard-output*);
  map(maybe-replace, dns-frame.name-servers);
  format-out("now additional-records\n");
  force-output(*standard-output*);
  map(maybe-replace, dns-frame.additional-records);
  format-out("now finished!\n");
  force-output(*standard-output*);
end method;

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

define method \= (a :: <domain-name>, b :: <domain-name>) => (res :: <boolean>)
  as(<string>, a) = as(<string>, b)
end;

define abstract protocol domain-name-fragment (variably-typed-container-frame)
  layering field type-code :: <2bit-unsigned-integer>;
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
    force-output(*standard-output*);
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

define method domain-names (question :: <dns-question>) => (l :: <list>);
  list(pair(domainname, domainname-setter))
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

define method domain-names (resource-record :: <dns-resource-record>) => (l :: <list>);
  list(pair(domainname, domainname-setter))
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

define method domain-names (name-server :: <name-server>) => (l :: <list>);
  list(pair(domainname, domainname-setter), pair(ns-name, ns-name-setter))
end;

define protocol canonical-name (dns-resource-record)
  summary "%= CNAME %=", domainname, cname; 
  over <dns-resource-record> 5;
  field cname :: <domain-name>;
end;

define method domain-names (canonical-name :: <canonical-name>) => (l :: <list>);
  list(pair(domainname, domainname-setter), pair(cname, cname-setter))
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

define method domain-names (soa :: <start-of-authority>) => (l :: <list>);
  list(pair(domainname, domainname-setter), pair(nameserver, nameserver-setter), pair(hostmaster, hostmaster-setter))
end;

define protocol domain-name-pointer (dns-resource-record)
  summary "%= PTR %=", domainname, ptr-name;
  over <dns-resource-record> 12;
  field ptr-name :: <domain-name>;
end;

define method domain-names (ptr :: <domain-name-pointer>) => (l :: <list>);
  list(pair(domainname, domainname-setter), pair(ptr-name, ptr-name-setter))
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

define method domain-names (mx :: <mail-exchange>) => (l :: <list>);
  list(pair(domainname, domainname-setter), pair(exchange, exchange-setter))
end;

define protocol text-strings (dns-resource-record)
  summary "%= TXT %=", domainname, text-data;
  over <dns-resource-record> 16;
  field text-data :: <character-string>;
end;

