Module:    icmp-responder
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define class <network-interface> (<object>)
  constant slot ethernet-address :: <mac-address>, init-keyword: mac-address:;
  constant slot ip-address :: <ipv4-address>, init-keyword: ipv4-address:;
end;

define class <arp-responder> (<filter>)
  slot network-interface :: <network-interface>, init-keyword: interface:;
end;

define method push-data-aux (input :: <push-input>,
                             node :: <arp-responder>,
                             frame :: <frame>)
  let response = make(<arp-frame>,
                      operation: 2,
                      source-mac-address: node.network-interface.ethernet-address,
                      source-ip-address: node.network-interface.ip-address,
                      target-mac-address: frame.source-mac-address,
                      target-ip-address: frame.source-ip-address);
  let response* = make(<ethernet-frame>,
                       destination-address: frame.source-mac-address,
                       source-address: node.network-interface.ethernet-address,
                       type-code: #x806,
                       payload: response);
  push-data(node.the-output, response*);
end;

define class <icmp-responder> (<filter>)
  slot network-interface :: <network-interface>, init-keyword: interface:;
end;

define method push-data-aux (input :: <push-input>,
                             node :: <icmp-responder>,
                             frame :: <frame>)
  let response = make(<icmp-frame>,
                      type: 0,
                      code: 0,
                      payload: frame.payload);
  let response* = make(<ipv4-frame>,
                       protocol: 1,
                       source-address: node.network-interface.ip-address,
                       destination-address: frame.parent.source-address,
                       payload: response,
                       options: make(<stretchy-vector>),
                       identification: 0);
  let response** = make(<ethernet-frame>,
                        destination-address: frame.parent.parent.source-address,
                        source-address: node.network-interface.ethernet-address,
                        type-code: #x800,
                        payload: response*);
  format-out("sending icmp response to %=\n", as(<string>, frame.parent.source-address));
  push-data(node.the-output, response**);
end;
begin
  let interface = make(<network-interface>,
                       mac-address: mac-address("00:de:ad:be:ef:00"),
                       ipv4-address: ipv4-address("23.23.23.5"));
  let demux = make(<demultiplexer>);
  let decap = make(<decapsulator>);
  let source = make(<pcap-interface>, name: "Intel");
  let printer = make(<summary-printer>, stream: *standard-output*);
  connect(source, decap);
  connect(decap, demux);
  let arp-output = create-output-for-filter(demux, "(arp.target-ip-address = 23.23.23.5) & (arp.operation = 1)");
  let icmp-output
    = create-output-for-filter(demux, "(ipv4.destination-address = 23.23.23.5) & ((icmp.type = 8) & (icmp.code = 0))");
  let arp-responder = make(<arp-responder>, interface: interface);
  let icmp-responder = make(<icmp-responder>, interface: interface);
  connect(arp-output, arp-responder);
  let ip-decap = make(<decapsulator>);
  let fan-in = make(<fan-in>);
  connect(fan-in, source);
  connect(icmp-output, ip-decap);
  connect(ip-decap, icmp-responder);
  connect(icmp-responder, fan-in);
  connect(arp-responder, fan-in);
  toplevel(source);
end;
