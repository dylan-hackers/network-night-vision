module: network-interfaces

define method find-all-devices () => (res :: <collection>)
  let res = make(<stretchy-vector>);
  let errbuf = make(<byte-vector>);
  let (errorcode, devices) = pcap-find-all-devices(buffer-offset(errbuf, 0));
  for (device = devices then device.next,
       while: device ~= null-pointer(<pcap-if*>))
    add!(res, make(<device>, name: as(<byte-string>, device.name)))
  end;
  res;
end;

define method initialize
    (interface :: <ethernet-interface>, #next next-method, #key, #all-keys)
  => ()
  next-method();
  let errbuf = make(<byte-vector>);
  let res = pcap-open-live(interface.interface-name,
                           $ethernet-buffer-size,
                           if (interface.promiscuous?) 1 else 0 end,
                           $timeout,
                           buffer-offset(errbuf, 0));
  if (res ~= null-pointer(<C-void*>))
    interface.pcap-t := res;
  end;
end;

