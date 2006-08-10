module: interfaces
author: Andreas Bogk, Hannes Mehnert
copyright: (c) 2006, All rights reserved. Free for non-commercial user


define simple-C-mapped-subtype <C-buffer-offset> (<C-char*>)
  export-map <machine-word>, export-function: identity;
end;

define method pcap-receive-callback
    (interface, packet :: <pcap-packet-header*>, bytes)
  let real-interface = import-c-dylan-object(interface);
  let res = make(<byte-vector>, size: packet.caplen);
  //XXX: performance!
  for (i from 0 below packet.caplen)
    res[i] := bytes[i];
  end;
  push-data(real-interface.the-output, make(unparsed-class(<ethernet-frame>), packet: res));
end;

define C-callable-wrapper receive-callback of pcap-receive-callback
  parameter user :: <C-dylan-object>;
  parameter packet :: <pcap-packet-header*>;
  parameter bytes :: <C-unsigned-char*>;
  c-name: "pcap_receive_callback";
end;

define C-function pcap-dispatch
  parameter p :: <C-void*>;
  parameter count :: <C-int>;
  parameter callback :: <C-function-pointer>;
  parameter user :: <C-dylan-object>;
  c-name: "pcap_dispatch";
end;

//XXX needed because bug #7192 c-ffi stuff needs to be compiled in tight mode
define generic interface-name (object :: <ethernet-interface>) => (res :: <string>);
define generic promiscious? (object :: <ethernet-interface>) => (res :: <boolean>);
define generic pcap-t (object :: <ethernet-interface>) => (res :: <object>);
define generic pcap-t-setter (value :: <object>, object :: <ethernet-interface>) => (res :: <object>);

define open class <ethernet-interface> (<filter>)
  constant slot interface-name :: <string> = "ath0", init-keyword: name:;
  constant slot promiscious? :: <boolean> = #t, init-keyword: promiscious?:;
  slot pcap-t;
end;

define C-function pcap-open-live
  parameter name :: <C-string>;
  parameter buffer-sizer :: <C-int>;
  parameter promisc :: <C-int>;
  parameter timeout :: <C-int>;
  parameter errbuf :: <C-buffer-offset>;
  result pcap-t :: <C-void*>;
  c-name: "pcap_open_live";
end;

define C-struct <timeval>
  slot tv_sec :: <C-int>;
  slot tv_usec :: <C-int>;
  c-name: "timeval";
end;

define C-struct <pcap-packet-header>
  slot ts :: <timeval>;
  slot caplen :: <C-int>;
  slot len :: <C-int>;
  pointer-type-name: <pcap-packet-header*>;
  c-name: "pcap_pkthdr";
end;

define constant $ethernet-buffer-size = 1600;
define constant $timeout = 100;

define method initialize
    (interface :: <ethernet-interface>, #next next-method, #key, #all-keys)
  => ()
  next-method();
  let errbuf = make(<byte-vector>);
  block(ret)
    local method open-interface (name)
            format-out("trying interface %s\n", name);
            let res = pcap-open-live(name,
                                     $ethernet-buffer-size,
                                     if (interface.promiscious?) 1 else 0 end,
                                     $timeout,
                                     buffer-offset(errbuf, 0));
            if (res ~= null-pointer(<C-void*>))
              interface.pcap-t := res;
              format-out("Opened Interface %s\n", name);
              ret();
            end;
          end;
    //open-interface(interface.interface-name);

    format-out("trying pcap-find-alldevices\n");
    let (errorcode, devices) = pcap-find-all-devices(buffer-offset(errbuf, 0));
    format-out("errcode %=\n", errorcode);
    for (device = devices then device.next, while: device ~= null-pointer(<pcap-if*>))
      format-out("device %s %s\n", device.name, device.description);
      if (subsequence-position(device.description, interface.interface-name))
        open-interface(device.name);
      end;
    end;
    error("Device %s not found", interface.interface-name);
  end;
end;
 
define C-struct <pcap-if>
  slot next :: <pcap-if*>;
  slot name :: <C-string>;
  slot description :: <C-string>;
  slot addresses :: <C-void*>;
  slot flags :: <C-unsigned-int>;
  pointer-type-name: <pcap-if*>;
  c-name: "pcap_if";
end;

define C-pointer-type <pcap-if**> => <pcap-if*>;
define C-function pcap-find-all-devices
  output parameter pcap-if-list :: <pcap-if**>;
  parameter errbuf :: <C-buffer-offset>;
  result errcode :: <C-int>;
  c-name: "pcap_findalldevs";
end;

define function buffer-offset
    (the-buffer :: <byte-vector>, data-offset :: <integer>)
 => (result-offset :: <machine-word>)
  u%+(data-offset,
      primitive-wrap-machine-word
        (primitive-repeated-slot-as-raw
           (the-buffer, primitive-repeated-slot-offset(the-buffer))))
end function;

define C-function pcap-inject
  parameter pcap-t :: <C-void*>;
  parameter buffer :: <C-buffer-offset>;
  parameter size :: <C-int>;
  result error :: <C-int>;
  c-name: "pcap_sendpacket";
end;

define method push-data-aux (input :: <push-input>,
                             node :: <ethernet-interface>,
                             frame :: <frame>)
  let buffer = assemble-frame(frame);
  let res = pcap-inject(node.pcap-t, buffer-offset(buffer, 0), buffer.size);
end;

define method toplevel (interface :: <ethernet-interface>)
  register-c-dylan-object(interface);
  while(#t)
    pcap-dispatch(interface.pcap-t,
                  1,
                  receive-callback,
                  export-c-dylan-object(interface));
  end;
end;

