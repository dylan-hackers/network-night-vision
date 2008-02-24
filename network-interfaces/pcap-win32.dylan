module: network-interfaces

define method find-all-devices () => (res :: <collection>)
  let res = make(<stretchy-vector>);
  let errbuf = make(<byte-vector>);
  let (errorcode, devices) = pcap-find-all-devices(buffer-offset(errbuf, 0));
  for (device = devices then device.next, while: device ~= null-pointer(<pcap-if*>))
    let cidrs = make(<stretchy-vector>);
    for (ele = device.addresses then ele.next, while: ele ~= null-pointer(<pcap-addr*>))
//      format-out("GOT as address %= ", ele.address.sa-family-value);
      local method printme (x)
              for (f from 2 below 6)
                //format-out("%X ", sa-data-array(x, f));
              end;
              //format-out(" ");
            end;
      printme(ele.address);
      if (null-pointer(<sockaddr*>) ~= ele.netmask)
       // format-out("netmask "); printme(ele.netmask);
      end;
      if (null-pointer(<sockaddr*>) ~= ele.broadcast-address)
        //format-out("broadcast-address "); printme(ele.broadcast-address);
      end;
      if (null-pointer(<sockaddr*>) ~= ele.destination-address)
        //format-out("destination-address "); printme(ele.destination-address);
      end;
      local method get-address (foo :: <pcap-addr*>)
              let res = make(<stretchy-vector-subsequence>, size: 4);
              for (i from 2 below 6)
                res[i - 2] := as(<byte>, sa-data-array(foo.address, i));
              end;
              make(<ipv4-address>, data: res);
            end;
      local method get-netmask (foo :: <pcap-addr*>)
              let res = make(<stretchy-vector>);
              for (i from 2 below 6)
                add!(res, sa-data-array(foo.netmask, i));
              end;
              netmask-from-byte-vector(res);
            end;

      //format-out("\n");
      add!(cidrs, concatenate(as(<string>, get-address(ele)), "/", integer-to-string(get-netmask(ele))));
    end;

    let str = as(<byte-string>, device.description);
    //XXX: generate a real object, and also return device-name
    add!(res, make(<device>, name: str, cidrs: cidrs))
  end;
  res;
end;

define method initialize
    (interface :: <ethernet-interface>, #next next-method, #key, #all-keys)
  => ()
  next-method();
  let errbuf = make(<byte-vector>);
  block(ret)
    local method open-interface (name)
//            format-out("trying interface %s\n", name);
            let res = pcap-open-live(name,
                                     $ethernet-buffer-size,
                                     if (interface.promiscuous?) 1 else 0 end,
                                     $timeout,
                                     buffer-offset(errbuf, 0));
            if (res ~= null-pointer(<C-void*>))
              interface.pcap-t := res;
//              format-out("Opened Interface %s\n", name);
              ret();
            end;
          end;
    //open-interface(interface.interface-name);

//    format-out("trying pcap-find-alldevices\n");
    let (errorcode, devices) = pcap-find-all-devices(buffer-offset(errbuf, 0));
//    format-out("errcode %=\n", errorcode);
    for (device = devices then device.next, while: device ~= null-pointer(<pcap-if*>))
//      format-out("device %s %s\n", device.name, device.description);
      if (subsequence-position(device.description, interface.interface-name))
        open-interface(device.name);
      end;
    end;
    error("Device %s not found", interface.interface-name);
  end;
end;

