module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define n-byte-vector(mac-address, 6) end;

define method read-frame(type == <mac-address>,
                         string :: <string>)
 => (res)
  let res = as-lowercase(string);
  if (any?(method(x) x = ':' end, res))
    //input: 00:de:ad:be:ef:00
    let fields = split(res, ':');
    unless(fields.size = 6)
      signal(make(<parse-error>))
    end;
    make(<mac-address>,
         data: map-as(<byte-vector>, rcurry(string-to-integer, base: 16), fields));
  else
    //input: 00deadbeef00
    unless (res.size = 12)
      signal(make(<parse-error>));
    end;
    let data = make(<byte-vector>, size: 6);
    for (i from 0 below data.size)
      data[i] := string-to-integer(res, start: i * 2, end: (i + 1) * 2, base: 16);
    end;
    make(<mac-address>, data: data);
  end;
end;

define method as (class == <string>, frame :: <mac-address>) => (string :: <string>);
  reduce1(method(a, b) concatenate(a, ":", b) end,
          map-as(<stretchy-vector>,
                 rcurry(integer-to-string, base: 16, size: 2),
                 frame.data))
end;

define protocol ethernet-frame (header-frame)
  summary "ETH %= -> %=/%s",
    source-address, destination-address, compose(summary, payload);
  field destination-address :: <mac-address>;
  field source-address :: <mac-address>;
  field type-code :: <2byte-big-endian-unsigned-integer>;
  variably-typed-field payload,
    type-function: payload-type(frame);
end;

define layer-bonding <ethernet-frame> (type-code)
  #x800 => <ipv4-frame>;
  #x806 => <arp-frame>
end;

