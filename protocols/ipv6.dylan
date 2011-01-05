module: ipv6
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define n-byte-vector(ipv6-address, 16) end;

define method read-frame (class == <ipv6-address>, data :: <string>) => (res :: <ipv6-address>)
  //XXXX:XXXX::XXXX
  let res = make(<stretchy-vector-subsequence>, size: 16, fill: 0);
  let numbers = split(data, ':');
  let rev-parse? = #f;
  local method set-bytes (offset :: <integer>, value :: <integer>)
          res[offset] := ash(value, -8);
          res[offset + 1] := logand(value, #xff);
        end;
  block (ret)
    for (n in numbers, i from 0 by 2)
      let n-size = n.size;
      if (n-size = 0)
        rev-parse? := #t;
        ret()
      else
        set-bytes(i, string-to-integer(n, base: 16));
      end;
    end;
  end;
  if (rev-parse?)
    block(ret)
      for (i from 14 to 0 by -2,
           n in reverse(numbers))
        if (n.size > 0)
          set-bytes(i, string-to-integer(n, base: 16));
        else
          ret();
        end;
      end;
    end;
  end;
  make(<ipv6-address>, data: res);
end;

define method as (class == <string>, ip :: <ipv6-address>) => (res :: <string>)
  let strings = make(<list>);
  for (i from 0 below 16 by 2)
    let count = ash(ip.data[i], 8) + ip.data[i + 1]; 
    strings := add!(strings, integer-to-string(count, base: 16));
  end;
  reduce1(method(x, y) concatenate(x, ":", y) end, reverse(strings));
end;

define protocol ipv6-frame (header-frame)
  summary "IPv6 %= -> %=", source-address, destination-address; 
  over <ethernet-frame> #x86dd;
  over <link-control> #x86dd;
  field version :: <4bit-unsigned-integer> = 6;
  field traffic-class :: <unsigned-byte> = 0;
  field flow-label :: <20bit-unsigned-integer>;
  field payload-length :: <2byte-big-endian-unsigned-integer>;
  layering field next-header :: <unsigned-byte>;
  field hop-limit :: <unsigned-byte>;
  field source-address :: <ipv6-address>;
  field destination-address :: <ipv6-address>;
  variably-typed-field payload,
    type-function: payload-type(frame),
    length: frame.payload-length * 8;
end; 

define protocol ipv6-extension-header (container-frame)
  field option-type :: <unsigned-byte>;
  field option-data-length :: <unsigned-byte>;
  field option-data :: <raw-frame>, length: frame.option-data-length * 8;
end;
















