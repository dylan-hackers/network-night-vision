module: cidr
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define class <cidr> (<object>)
  constant slot cidr-network-address,
    //<ipv4-address>, but somehow this confuses the compiler (runtime)
    required-init-keyword: network-address:;
  constant slot cidr-netmask :: <integer>,
    required-init-keyword: netmask:;
end class;

define method base-network-address (cidr :: <cidr>)
 => (ip-address :: <ipv4-address>)
  let (bytes, bits) = truncate/(cidr.cidr-netmask, 8);
  let data-vector = make(<vector>, size: 4, fill: 0);
  for (i from 0 below bytes)
    data-vector[i] := cidr.cidr-network-address.data[i];
  end;
  if ((bytes < 4) & (bits > 0))
    let mask = logand(#xff, ash(#xff, 8 - bits));
    data-vector[bytes] := logand(mask, cidr.cidr-network-address.data[bytes]);
  end;
  parse-frame(<ipv4-address>, data-vector)
end;

define method \= (a :: <cidr>, b :: <cidr>) => (res :: <boolean>)
  (a.cidr-netmask == b.cidr-netmask) & (base-network-address(a) = base-network-address(b))
end;
define method ip-in-cidr? (cidr :: <cidr>, ipv4-address :: <ipv4-address>)
  let (bytes, bits) = truncate/(cidr.cidr-netmask, 8);
  block(ret)
    for (i from 0 below bytes)
      unless (ipv4-address.data[i] = cidr.cidr-network-address.data[i])
        ret(#f)
      end;
    end;
    if ((bytes < 4) & (bits > 0))
      let mask = logand(#xff, ash(#xff, 8 - bits));
      unless (logand(mask, ipv4-address.data[bytes]) = logand(mask, cidr.cidr-network-address.data[bytes]))
        ret(#f)
      end;
    end;
    #t;
  end;
end;
define method print-object (cidr :: <cidr>, stream :: <stream>)
 => ()
  format(stream, "%s", as(<string>, cidr));
end;

define method as (class == <string>, cidr :: <cidr>)
 => (res :: <string>)
  concatenate(as(<string>, cidr-network-address(cidr)), "/",
              integer-to-string(cidr.cidr-netmask));
end;

define method as(class == <cidr>, string :: <string>)
 => (res :: <cidr>)
  let address-and-mask = split(string, '/');
  unless (address-and-mask.size = 2)
    signal(make(<error>, error: "CIDR syntax wrong IP/Netmask[prefixlen]"));
  end;
  let network-address = address-and-mask[0];
  let netmask = address-and-mask[1];
  network-address := ipv4-address(network-address);
  netmask := string-to-integer(netmask);
  make(<cidr>, network-address: network-address, netmask: netmask)
end;

define method broadcast-address (cidr :: <cidr>) => (res :: <ipv4-address>);
  let res = ipv4-address(as(<string>, cidr.cidr-network-address));
  let (bytes, bits) = truncate/(32 - cidr.cidr-netmask, 8);
  for (i from 0 below bytes)
    res.data[3 - i] := #xff;
  end;
  if (bits > 0)
    res.data[3 - bytes] := logior(res.data[3 - bytes], logand(#xff, 2 ^ bits - 1));
  end;
  res;
end;
define constant $dec-to-netmask = make(<vector>, size: 256, fill: #f);
begin
  $dec-to-netmask[255] := 7;
  $dec-to-netmask[254] := 6;
  $dec-to-netmask[248] := 5;
  $dec-to-netmask[240] := 4;
  $dec-to-netmask[224] := 3;
  $dec-to-netmask[192] := 2;
  $dec-to-netmask[128] := 1;
  $dec-to-netmask[0] := 0;
end;

define function netmask-from-byte-vector (bv :: <collection>) => (res :: <integer>)
  block (ret)
    for (ele in bv, j from 0 by 8)
      unless (ele = 255)
        let off = $dec-to-netmask[ele];
        unless (off)
          format-out("Invalid netmask, returning %d! %=\n", j, ele);
          ret(j);
        end;
        ret(j + off);
      end;
    end;
    32;
  end;
end;

