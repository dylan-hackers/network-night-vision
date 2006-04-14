module: pcap-wrapper
author: Andreas Bogk, Hannes Mehnert
copyright: (c) 2006, All rights reserved. Free for non-commercial user


define simple-C-mapped-subtype <C-buffer-offset> (<C-char*>)
  export-map <machine-word>, export-function: identity;
end;

define method pcap-receive-callback
    (interface, packet :: <pcap-packet-header*>, bytes)
  let real-interface = import-c-dylan-object(interface);
  let res = make(<byte-vector>, size: packet.caplen);
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

define open generic device-name (object :: <pcap-interface>) => (res :: <string>);
define open generic pcap-t (object :: <pcap-interface>) => (res :: <object>);
define open generic pcap-t-setter (value :: <object>, object :: <pcap-interface>) => (res :: <object>);

define open class <pcap-interface> (<filter>)
  constant slot device-name :: <string> = "ath0", init-keyword: name:;
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
define constant $promisc = 1;
define constant $timeout = 100;

define method initialize
    (interface :: <pcap-interface>, #next next-method, #key, #all-keys)
  => ()
  next-method();
  let errbuf = make(<byte-vector>);
  interface.pcap-t :=
    pcap-open-live(interface.device-name,
                   $ethernet-buffer-size,
                   $promisc,
                   $timeout,
                   buffer-offset(errbuf, 0));
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
  c-name: "pcap_inject";
end;

define method push-data-aux (input :: <push-input>,
                             node :: <pcap-interface>,
                             frame :: <frame>)
  let buffer = assemble-frame(frame);
  let res = pcap-inject(node.pcap-t, buffer-offset(buffer, 0), buffer.size);
end;

begin
  let pcap = make(<pcap-interface>);
  let fan-out = make(<fan-out>);
  connect(pcap, fan-out);
  connect(fan-out, make(<summary-printer>, stream: *standard-output*));
  connect(fan-out, pcap);
  register-c-dylan-object(pcap);
  while(#t)
    pcap-dispatch(pcap.pcap-t, 1, receive-callback, export-c-dylan-object(pcap));
  end;
end;
