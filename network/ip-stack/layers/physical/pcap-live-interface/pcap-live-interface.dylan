module: pcap-live-interface

define class <pcap-flow-node> (<filter>)
  slot pcap-t :: <C-void*>;
end;

define constant $ethernet-buffer-size = 1600;
define constant $timeout = 100;

define layer pcap (<physical-layer>)
  property administrative-state :: <symbol> = #"down";
  property promiscuous? :: <boolean> = #t;
  system property running-state :: <symbol> = #"down";
  system property device-id :: <string>;
  system property device-description :: <string>;
  slot pcap-flow-node :: <pcap-flow-node>;
end;

define method create-raw-socket (pcap :: <pcap-layer>) => (res :: <node>)
  pcap.pcap-flow-node;
end;
define method initialize-layer
    (layer :: <pcap-layer>, #key, #all-keys)
  => ()
  layer.pcap-flow-node := make(<pcap-flow-node>);
  register-c-dylan-object(layer.pcap-flow-node);
  register-property-changed-event(layer, #"administrative-state", toggle-administrative-state);
end;

define function toggle-administrative-state (event :: <property-changed-event>) => ();
  let property = event.property-changed-event-property;
  let layer = property.property-owner;
  if (property.property-value == #"up")
    make(<thread>, function: curry(run-interface, layer));
  else
    layer.@running-state := #"down";    
  end;
end;

define method pcap-receive-callback
    (interface, packet :: <pcap-packet-header*>, bytes)
  let real-interface = import-c-dylan-object(interface);
  let res = make(<byte-vector>, size: packet.caplen);
  //XXX: performance!
  for (i from 0 below packet.caplen)
    res[i] := bytes[i];
  end;
  push-data(real-interface.the-output, parse-frame(<ethernet-frame>, res));
end;

define C-callable-wrapper receive-callback of pcap-receive-callback
  parameter user :: <C-dylan-object>;
  parameter packet :: <pcap-packet-header*>;
  parameter bytes :: <C-unsigned-char*>;
  c-name: "pcap_receive_callback";
end;

define method push-data-aux (input :: <push-input>,
                             node :: <pcap-flow-node>,
                             frame :: <frame>)
  let buffer = as(<byte-vector>, assemble-frame(frame).packet);
  pcap-inject(node.pcap-t, buffer-offset(buffer, 0), buffer.size);
end;

define function run-interface (layer :: <pcap-layer>)
  block(return)
    let node = layer.pcap-flow-node;
    let pcap-handle = 
      with-c-string (null-string = "")
        pcap-open-live(layer.@device-id,
                       $ethernet-buffer-size,
                       if (layer.@promiscuous?) 1 else 0 end,
                       $timeout,
                       null-string);
      end;
    if (pcap-handle = null-pointer(<C-void*>))
      layer.@running-state := #"error";
      return();
    end;
    node.pcap-t := pcap-handle;
    layer.@running-state := #"up";
    while(layer.@running-state == #"up")
      pcap-dispatch(pcap-handle,
                    1,
                    receive-callback,
                    export-c-dylan-object(node));
    end;
    pcap-close(node.pcap-t);
  end;
end;

define C-function pcap-dispatch
  parameter p :: <C-void*>;
  parameter count :: <C-int>;
  parameter callback :: <C-function-pointer>;
  parameter user :: <C-dylan-object>;
  c-name: "pcap_dispatch";
end;

define C-function pcap-open-live
  parameter name :: <C-string>;
  parameter buffer-sizer :: <C-int>;
  parameter promisc :: <C-int>;
  parameter timeout :: <C-int>;
  parameter errbuf :: <C-string>;
  result pcap-t :: <C-void*>;
  c-name: "pcap_open_live";
end;

define C-struct <pcap-packet-header>
  slot ts :: <timeval>;
  slot caplen :: <C-int>;
  slot len :: <C-int>;
  pointer-type-name: <pcap-packet-header*>;
  c-name: "pcap_pkthdr";
end;



define constant <sockaddr*> = <LPSOCKADDR>;
define C-struct <pcap-addr>
  slot next :: <pcap-addr*>;
  slot address :: <sockaddr*>;
  slot netmask :: <sockaddr*>;
  slot broadcast-address :: <sockaddr*>;
  slot destination-address :: <sockaddr*>;
  pointer-type-name: <pcap-addr*>;
  c-name: "pcap_addr";
end;

define C-struct <pcap-if>
  slot next :: <pcap-if*>;
  slot name :: <C-string>;
  slot description :: <C-string>;
  slot addresses :: <pcap-addr*>;
  slot flags :: <C-unsigned-int>;
  pointer-type-name: <pcap-if*>;
  c-name: "pcap_if";
end;

define C-pointer-type <pcap-if**> => <pcap-if*>;
define C-function pcap-find-all-devices
  output parameter pcap-if-list :: <pcap-if**>;
  parameter errbuf :: <C-string>;
  result errcode :: <C-int>;
  c-name: "pcap_findalldevs";
end;

define C-function pcap-free-all-devices
  parameter pcap-if-list :: <pcap-if*>;
  c-name: "pcap_freealldevs";
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

define C-function pcap-close
  parameter pcap-t :: <C-void*>;
  //result error :: <C-void>;
  c-name: "pcap_close";
end;

define function start-pcap ()
  with-c-string (errbuf = "")
    let (errorcode, devices) = pcap-find-all-devices(errbuf);
    for (device = devices then device.next, while: device ~= null-pointer(<pcap-if*>))
      make(<pcap-layer>, device-id: as(<byte-string>, device.name), device-description: as(<byte-string>, device.description));
    end;
    pcap-free-all-devices(devices);
  end;
end;

begin
  register-startup-function(start-pcap);
end;

