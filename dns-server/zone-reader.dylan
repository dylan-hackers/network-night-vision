module: dns-server


define function dns-query-entry (x :: <symbol>) => (res :: <character>)
  select (x)
    #"A" => '+';
    #"NS" => '&';
    #"CNAME" => 'C';
    #"SOA" => 'Z';
    #"PTR" => '^';
    #"MX" => '@';
    #"TXT" => '\'';
    #"ANY" => '*';
  end;
end;

define class <zone> (<object>)
  constant slot entries = make(<stretchy-vector>)
end;

define abstract class <entry> (<object>)
  constant slot entry-type :: <symbol>;
  constant slot fully-qualified-domain-name :: <string>, required-init-keyword: name:;
  constant slot dns-time-to-live :: <integer> = 86400, init-keyword: ttl:;
end;

define constant $tbv = compose(big-endian-unsigned-integer-4byte, float-to-byte-vector-be, curry(as, <float>));

define class <a-entry> (<entry>)
  inherited slot entry-type = #"A";
  constant slot ip-address :: <string>, required-init-keyword: ip:;
end;

define method print-object (e :: <a-entry>, stream :: <stream>) => ()
  format(stream, "+%s:%s:%d", e.fully-qualified-domain-name, e.ip-address, e.dns-time-to-live)
end;

define method produce-frame (e :: <a-entry>) => (f :: <dns-resource-record>)
  let dn = as(<domain-name>, e.fully-qualified-domain-name);
  let res = a-host-address(domainname: dn,
                           ttl: $tbv(e.dns-time-to-live),
                           ipv4-address: ipv4-address(e.ip-address));
  dn.parent := res;
  res;
end;

define class <ns-entry> (<entry>)
  inherited slot entry-type = #"NS";
  constant slot nameserver-name :: <string>, required-init-keyword: ns:;
end;

define method print-object (e :: <ns-entry>, stream :: <stream>) => ()
  format(stream, "&%s::%s:%d", e.fully-qualified-domain-name, e.nameserver-name, e.dns-time-to-live)
end;

define method produce-frame (e :: <ns-entry>) => (f :: <dns-resource-record>)
  let dn = as(<domain-name>, e.fully-qualified-domain-name);
  let dn2 = as(<domain-name>, e.nameserver-name);
  let res = name-server(domainname: dn, ttl: $tbv(e.dns-time-to-live), ns-name: dn2);
  dn.parent := res;
  dn2.parent := res;
  res;
end;

define class <cname-entry> (<entry>)
  inherited slot entry-type = #"CNAME";
  constant slot real-name :: <string>, required-init-keyword: cname:;
end;

define method print-object (e :: <cname-entry>, stream :: <stream>) => ()
  format(stream, "C%s:%s:%d", e.fully-qualified-domain-name, e.real-name, e.dns-time-to-live)
end;

define method produce-frame (e :: <cname-entry>) => (f :: <dns-resource-record>)
  let dn = as(<domain-name>, e.fully-qualified-domain-name);
  let dn2 = as(<domain-name>, e.real-name);
  let res = canonical-name(domainname: dn, ttl: $tbv(e.dns-time-to-live), cname: dn2);
  dn.parent := res;
  dn2.parent := res;
  res;
end;

define class <soa-entry> (<entry>)
  inherited slot entry-type = #"SOA";
  constant slot primary-name-server :: <string>, required-init-keyword: ns:;
  constant slot soa-hostmaster :: <string>, required-init-keyword: hostmaster:;
  constant slot soa-serial :: <integer> = *modification-date*, init-keyword: serial:;
  constant slot soa-refresh :: <integer> = 16384, init-keyword: refresh:;
  constant slot soa-retry :: <integer> = 2048, init-keyword: retry:;
  constant slot soa-expiry :: <integer> = 1048576, init-keyword: expiry:;
  constant slot soa-minimum :: <integer> = 2560, init-keyword: minimum:;
end;

define method print-object (e :: <soa-entry>, stream :: <stream>) => ()
  format(stream, "Z%s:%s:%s:%d:%d:%d:%d:%d:%d", e.fully-qualified-domain-name, e.primary-name-server, e.soa-hostmaster, e.soa-serial, e.soa-refresh, e.soa-retry, e.soa-expiry, e.soa-minimum, e.dns-time-to-live)
end;

define method produce-frame (e :: <soa-entry>) => (f :: <dns-resource-record>)
  let dn = as(<domain-name>, e.fully-qualified-domain-name);
  let dn2 = as(<domain-name>, e.primary-name-server);
  let dn3 = as(<domain-name>, e.soa-hostmaster);
  let res = start-of-authority(domainname: dn, nameserver: dn2, hostmaster: dn3,
                               ttl: $tbv(e.dns-time-to-live),
                               serial: $tbv(e.soa-serial),
                               refresh: $tbv(e.soa-refresh),
                               retry: $tbv(e.soa-retry),
                               expire: $tbv(e.soa-expiry),
                               minimum: $tbv(e.soa-minimum));
  dn.parent := res;
  dn2.parent := res;
  dn3.parent := res;
  res;
end;

define class <ptr-entry> (<entry>)
  inherited slot entry-type = #"PTR";
  constant slot ptr-entry-name :: <string>, required-init-keyword: ptr-name:;
end;

define method print-object (e :: <ptr-entry>, stream :: <stream>) => ()
  format(stream, "^%s:%s:%d", e.fully-qualified-domain-name, e.ptr-entry-name, e.dns-time-to-live)
end;

define method produce-frame (e :: <ptr-entry>) => (f :: <dns-resource-record>)
  let dn = as(<domain-name>, e.fully-qualified-domain-name);
  let dn2 = as(<domain-name>, e.ptr-entry-name);
  let res = domain-name-pointer(domainname: dn, ttl: $tbv(e.dns-time-to-live), ptr-name: dn2);
  dn.parent := res;
  dn2.parent := res;
  res;
end;

define class <mx-entry> (<entry>)
  inherited slot entry-type = #"MX";
  constant slot mx-name :: <string>, required-init-keyword: mx:;
  constant slot mx-priority :: <integer>, required-init-keyword: priority:;
end;

define method print-object (e :: <mx-entry>, stream :: <stream>) => ()
  format(stream, "@%s::%s:%d:%d", e.fully-qualified-domain-name, e.mx-name, e.mx-priority, e.dns-time-to-live)
end;

define method produce-frame (e :: <mx-entry>) => (f :: <dns-resource-record>)
  let dn = as(<domain-name>, e.fully-qualified-domain-name);
  let dn2 = as(<domain-name>, e.mx-name);
  let res = mail-exchange(domainname: dn, ttl: $tbv(e.dns-time-to-live), exchange: dn2, preference: e.mx-priority);
  dn.parent := res;
  dn2.parent := res;
  res;
end;

define class <txt-entry> (<entry>)
  inherited slot entry-type = #"TXT";
  constant slot text :: <string>, required-init-keyword: text:;
end;

define method print-object (e :: <txt-entry>, stream :: <stream>) => ()
  format(stream, "'%s:%s:%d", e.fully-qualified-domain-name, e.text, e.dns-time-to-live)
end;

define method produce-frame (e :: <txt-entry>) => (f :: <dns-resource-record>)
  let dn = as(<domain-name>, e.fully-qualified-domain-name);
  let res = text-strings(domainname: dn, ttl: $tbv(e.dns-time-to-live),
                         text-data: as(<character-string>, e.text));
  dn.parent := res;
  res;
end;

define variable *modification-date* :: <integer> = 1366287700;

define method read-zone (filename :: <string>) => (res :: <zone>)
  let res = make(<zone>);
  //TODO: *modification-date* := file-property(filename, #"modification-date");
  with-open-file (s = filename)
    while (~ stream-at-end?(s))
      let line = read-line(s);
      if (line.size > 0 & line[0] ~== '#')
        let ent = read-entry(line);
        do(curry(add!, res.entries), ent);
      end;
    end;
  end;
  res
end;

define method read-entry (entry :: <string>) => (ent :: <list>)
  let res = #();
  let ps = split(copy-sequence(entry, start: 1), ':');
  let ttl-finder = method (x :: <integer>)
                     block ()
                       list(#"ttl", string-to-integer(ps[x]))
                     exception (c :: <condition>)
                       #()
                     end;
                   end;
  select (entry[0])
    '.' =>
      let ttl = ttl-finder(3);
      res := add!(res, apply(make, <ns-entry>, name: ps[0], ns: ps[2], ttl));
      if (ps[1].size > 0)
        res := add!(res, apply(make, <a-entry>, name: ps[2], ip: ps[1], ttl));
      end;
      res := add!(res, apply(make, <soa-entry>, name: ps[0], ns: ps[2], hostmaster: concatenate("hostmaster.", ps[0]), ttl));
    '&' =>
      let ttl = ttl-finder(3);
      res := add!(res, apply(make, <ns-entry>, name: ps[0], ns: ps[2], ttl));
      if (ps[1].size > 0)
        res := add!(res, apply(make, <a-entry>, name: ps[2], ip: ps[1], ttl));
      end;
    '+' =>
      let ttl = ttl-finder(2);
      res := add!(res, apply(make, <a-entry>, name: ps[0], ip: ps[1], ttl));
    '=' =>
      let ttl = ttl-finder(2);
      res := add!(res, apply(make, <a-entry>, name: ps[0], ip: ps[1], ttl));
      res := add!(res, apply(make, <ptr-entry>, name: ptr-convert(ps[1]), ptr-name: ps[0], ttl));
    '@' =>
      let ttl = ttl-finder(4);
      res := add!(res, apply(make, <mx-entry>, name: ps[0], mx: ps[2], priority: string-to-integer(ps[3]), ttl));
      if (ps[1].size > 0)
        res := add!(res, apply(make, <a-entry>, name: ps[2], ip: ps[1], ttl));
      end;
    '\'' =>
      let ttl = ttl-finder(2);
      res := add!(res, apply(make, <txt-entry>, name: ps[0], text: ps[1], ttl));
    'C' =>
      let ttl = ttl-finder(2);
      res := add!(res, apply(make, <cname-entry>, name: ps[0], cname: ps[1], ttl));
    'Z' =>
      //XXX: todo: parse fields 3 - 7!
      let ttl = ttl-finder(8);
      res := add!(res, apply(make, <soa-entry>, name: ps[0], ns: ps[1], hostmaster: ps[2], ttl));
    '^' =>
      let ttl = ttl-finder(2);
      res := add!(res, apply(make, <ptr-entry>, name: ps[0], ptr-name: ps[1], ttl));
    otherwise => dbg("falled through select\n");
  end;
  res;
end;

define function ptr-convert (string :: <string>) => (res :: <string>)
  let ps = split(string, '.');
  concatenate(join(reverse(ps), "."), ".in-addr.arpa")
end;


