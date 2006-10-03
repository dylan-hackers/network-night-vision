module: layer


define open generic cidr-network-address (cidr :: <cidr>) => (res :: <ipv4-address>);
define open generic cidr-netmask (cidr :: <cidr>) => (res :: <integer>);

define class <cidr> (<object>)
  constant slot cidr-network-address :: <ipv4-address>,
    required-init-keyword: network-address:;
  constant slot cidr-netmask :: <integer>,
    required-init-keyword: netmask:;
end class;


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

define method as (class == <cidr>, string :: <string>)
 => (res :: <cidr>)
  let (ip, mask) = apply(values, split(string, '/'));
  make(<cidr>,
       network-address: ipv4-address(ip),
       netmask: string-to-integer(mask));
end;
