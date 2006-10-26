Module:    layer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

//a layer contains a fan-out, demultiplexer and fan-in.
// it also has a send-socket for sending packets
//
//a socket contains one input and one output
// two types of sockets can be created
//  raw-socket without any filters: raw-socket(layer)
//   connects itself to fan-in and fan-out
//  socket (layer, type-code/port/whatever, source-address: source-address)
//   creates an output for the filter rule in the demultiplexer,
//    connects its input to it
//   adds an completer with template-frame (generated from filter rule),
//    connects its output to it
//
// a socket implements the following methods:
//  sendto(socket, destination, payload)
//   which 
//  receive-callback(socket, method) // method gets one argument: a frame
//   which is called in push-data-aux(socket-input, socket, frame)
//
// an adapter connects layers with sockets and does adapter-specific stuff
//  it installs a decapsulator and encapsulator
//  creates a socket in bottom layer (with protocol-specific information in filter rule)
//  sets socket receive-callback to curry(push-data, upper-layer-input)
//  sets upper-layer send-socket to itself

//
//  ethernet-layer
// fan-in     fan-out
//           demultiplexer
//
//    ethernet-socket
// completer  demux-output
//  (#x800)    (#x800)
//
//   ip-over-ethernet-adapter
// encapsulator       decapsulator
// (dest: find-mac)

define open generic fan-in (object :: <layer>) => (res :: <fan-in>);
define open generic demultiplexer (object :: <layer>) => (res :: <demultiplexer>);
define open generic sockets (object :: <layer>) => (res :: <collection>);

define abstract class <layer> (<object>)
  constant slot fan-in :: <fan-in> = make(<fan-in>);
  constant slot demultiplexer :: <demultiplexer> = make(<demultiplexer>);
  constant slot sockets :: <collection> = make(<stretchy-vector>);
end;

define open generic demultiplexer-output (object :: <socket>) => (res :: <object>);
define open generic demultiplexer-output-setter (value :: <object>, object :: <socket>) => (res :: <object>);
define open generic decapsulator (object :: <socket>) => (res :: <decapsulator>);
define open generic completer (object :: <socket>) => (res :: <completer>);
define open generic completer-setter (value :: <completer>, object :: <socket>) => (res :: <completer>);

define abstract class <socket> (<object>)
  constant slot decapsulator :: <decapsulator> = make(<decapsulator>);
  slot demultiplexer-output;
  slot completer :: <completer>;
end;

define abstract class <adapter> (<object>)
end;

define generic ethernet-interface (object :: <ethernet-layer>) => (res :: <ethernet-interface>);
define generic ethernet-interface-setter (object :: <ethernet-interface>, object2 :: <ethernet-layer>) => (res :: <ethernet-interface>);
define generic default-mac-address (object :: <ethernet-layer>) => (res :: <mac-address>);
define generic default-mac-address-setter (object :: <mac-address>, object2 :: <ethernet-layer>) => (res :: <mac-address>);

define class <ethernet-layer> (<layer>)
  slot ethernet-interface :: <ethernet-interface>,
    required-init-keyword: ethernet-interface:;
  slot default-mac-address :: <mac-address> = mac-address("00:de:ad:be:ef:01"),
    init-keyword: default-mac-address:;
end;

define method initialize (layer :: <ethernet-layer>,
                          #rest rest, #key, #all-keys);
  connect(layer.fan-in, layer.ethernet-interface);
  connect(layer.ethernet-interface, layer.demultiplexer);
end;

define open generic ethernet-type-code (object :: <ethernet-socket>) => (res :: <integer>);
define open generic listen-address (object :: <object>) => (res :: <object>);

define class <ethernet-socket> (<socket>)
  constant slot ethernet-type-code :: <integer>, init-keyword: type-code:;
  constant slot listen-address :: false-or(<mac-address>) = #f, init-keyword: listen-address:;
end;

define method create-socket (layer :: <ethernet-layer>,
                             type-code :: <integer>,
                             #key mac-address)
 => (socket :: <ethernet-socket>);
  let source-address = mac-address | layer.default-mac-address;
  let socket = make(<ethernet-socket>,
                    type-code: type-code,
                    listen-address: source-address);
  let template-frame = make(<ethernet-frame>,
                            type-code: type-code,
                            source-address: source-address);
  socket.completer := make(<completer>,
                           template-frame: template-frame);
  socket.demultiplexer-output
    := create-output-for-filter(layer.demultiplexer,
                                format-to-string("(ethernet.destination-address = %s) & (ethernet.type-code = %s)",
                                                 source-address, type-code));
  connect(socket.demultiplexer-output, socket.decapsulator);
  connect(socket.completer, layer.fan-in);
  socket;
end;

define method send (socket :: <ethernet-socket>, destination :: <mac-address>, payload :: <container-frame>);
  let ethernet-frame = make(<ethernet-frame>,
                            destination-address: destination,
                            payload: payload);
  push-data-aux(socket.completer.the-input, socket.completer, ethernet-frame);
end;


define method delete-socket (socket :: <ethernet-socket>, layer :: <ethernet-layer>)
  disconnect(socket.demultiplexer-output, socket.decapsulator);
  disconnect(socket.completer, layer.fan-in);
end;

define open generic ethernet-layer (object :: <ip-over-ethernet-adapter>) => (res :: <ethernet-layer>);
define generic arp-handler (object :: <ip-over-ethernet-adapter>) => (res :: <arp-handler>);
define generic v4-address (object :: <ip-over-ethernet-adapter>) => (res :: <ipv4-address>);
define open generic ip-layer (object :: <object>) => (res :: <ip-layer>);
define open generic ip-layer-setter (value :: <ip-layer>, object :: <object>) => (res :: <ip-layer>);
define open generic ip-send-socket (object) => (res :: <socket>);
define open generic ip-send-socket-setter (value :: <socket>, object) => (res :: <socket>);
define open generic netmask (object :: <ip-over-ethernet-adapter>) => (res :: <integer>);

define class <ip-over-ethernet-adapter> (<adapter>)
  constant slot ip-layer :: <ip-layer>, required-init-keyword: ip-layer:;
  constant slot ethernet-layer :: <ethernet-layer>, required-init-keyword: ethernet:;
  constant slot arp-handler :: <arp-handler>, required-init-keyword: arp:;
  constant slot v4-address :: <ipv4-address>, required-init-keyword: ipv4-address:;
  constant slot netmask :: <integer>, required-init-keyword: netmask:;
  slot ip-send-socket :: <ethernet-socket>;
end;

define method send (socket :: <ip-over-ethernet-adapter>, destination :: <ipv4-address>, payload :: <container-frame>);
  let arp-entry = element(socket.arp-handler.arp-table, destination, default: #f);
  if (instance?(arp-entry, <known-arp-entry>))
    send(socket.ip-send-socket, arp-entry.arp-mac-address, payload);
  else
    let arp-handler = socket.arp-handler;
    with-lock(arp-handler.table-lock)
      if (arp-entry)
        arp-entry.outstanding-packets := add!(arp-entry.outstanding-packets, payload);
      else
        let from-addr = arp-handler.send-socket.listen-address;
        let from-ip = find-key(arp-handler.arp-table,
                               method(x)
                                 x.arp-mac-address = from-addr
                               end);
        let arp-request = make(<arp-frame>,
                               operation: 1,
                               source-mac-address: from-addr,
                               source-ip-address: from-ip,
                               target-ip-address: destination,
                               target-mac-address: mac-address("00:00:00:00:00:00"));
        send(arp-handler.send-socket, $broadcast-ethernet-address, arp-request);
        let outstanding-request = make(<outstanding-arp-request>,
                                       handler: arp-handler,
                                       request: arp-request,
                                       destination: $broadcast-ethernet-address,
                                       ip-address: destination,
                                       outstanding-packets: list(payload));
        let timer* = make(<timer>, in: 5, event: curry(try-again, outstanding-request, arp-handler));
        outstanding-request.timer := timer*;
        arp-handler.arp-table[destination] := outstanding-request;
        arp-entry := outstanding-request;
      end;
    end;
  end;
end;

define constant $broadcast-ethernet-address = mac-address("ff:ff:ff:ff:ff:ff");

define method initialize (ip-over-ethernet :: <ip-over-ethernet-adapter>,
                          #rest rest, #key, #all-keys);
  let arp-socket = create-socket(ip-over-ethernet.ethernet-layer, #x806);
  let arp-broadcast-socket = create-socket(ip-over-ethernet.ethernet-layer,
                                           #x806,
                                           mac-address: $broadcast-ethernet-address);
  let arp-fan-in = make(<fan-in>);
  connect(arp-socket.decapsulator, arp-fan-in);
  connect(arp-broadcast-socket.decapsulator, arp-fan-in);
  connect(arp-fan-in, ip-over-ethernet.arp-handler);

  ip-over-ethernet.arp-handler.send-socket := arp-socket;

  ip-over-ethernet.arp-handler.arp-table[ip-over-ethernet.v4-address]
    := make(<advertised-arp-entry>,
            ip-address: ip-over-ethernet.v4-address,
            mac-address: ip-over-ethernet.ethernet-layer.default-mac-address);


  let ip-socket = create-socket(ip-over-ethernet.ethernet-layer, #x800);
  let ip-broadcast-socket = create-socket(ip-over-ethernet.ethernet-layer,
                                          #x800,
                                          mac-address: $broadcast-ethernet-address);
  ip-over-ethernet.ip-send-socket := ip-socket;
  ip-over-ethernet.arp-handler.ip-send-socket := ip-socket;
  let ipv4-fan-in = make(<fan-in>);
  connect(ip-socket.decapsulator, ipv4-fan-in);
  connect(ip-broadcast-socket.decapsulator, ipv4-fan-in);
  connect(ipv4-fan-in, ip-over-ethernet.ip-layer.demultiplexer);

  register-adapter(ip-over-ethernet.ip-layer, ip-over-ethernet);
  ip-over-ethernet.ip-layer.default-ip-address := ip-over-ethernet.v4-address;
end; 


define open generic send-socket (object :: <object>) => (res);
define open generic send-socket-setter (value :: <object>, object :: <object>) => (res);
define generic default-ip-address (object :: <layer>) => (res :: <ipv4-address>);
define generic default-ip-address-setter (value :: <ipv4-address>, object :: <layer>) => (res :: <ipv4-address>);
define open generic adapters (object :: <ip-layer>) => (res);
define open generic routes (object :: <ip-layer>) => (res);

define class <ip-layer> (<layer>)
  slot send-socket :: type-union(<socket>, <adapter>);
  constant slot adapters = make(<stretchy-vector>);
  slot default-ip-address :: <ipv4-address>;
  constant slot routes = make(<stretchy-vector>);
end;

define class <route> (<object>)
  constant slot cidr :: <cidr>, required-init-keyword: cidr:;
end;

define generic next-hop (object :: <next-hop-route>) => (res :: <ipv4-address>);

define class <next-hop-route> (<route>)
  constant slot next-hop :: <ipv4-address>, required-init-keyword: next-hop:;
end;

define generic adapter (object :: <connected-route>) => (res :: <adapter>);
define class <connected-route> (<route>)
  constant slot adapter :: <adapter>, required-init-keyword: adapter:;
end;

define method register-route (ip :: <ip-layer>, route :: <route>)
  add!(ip.routes, route);
  sort!(ip.routes, test: method(x, y) x.cidr.cidr-netmask > y.cidr.cidr-netmask end)
end;

define method initialize (ip-layer :: <ip-layer>,
                          #rest rest, #key, #all-keys);
  let cls = make(<closure-node>,
                 closure: method(x)
                            let (adapter, next-hop)
                              = find-adapter-for-forwarding(ip-layer, x.destination-address);
                            send(adapter, next-hop, x)
                          end);
  connect(ip-layer.fan-in, cls);
end;
define method register-adapter (ip :: <ip-layer>,
                                adapter :: <ip-over-ethernet-adapter>)
  add!(ip.adapters, adapter);
  let route = make(<connected-route>,
                   cidr: make(<cidr>, netmask: adapter.netmask, network-address: adapter.v4-address),
                   adapter: adapter);
  register-route(ip, route);
end;

define method unregister-adapter (ip :: <ip-layer>,
                                  adapter :: <adapter>)
  remove!(ip.adapters, adapter);
end;

define method find-route (forwarding-table, destination :: <ipv4-address>) => (route :: false-or(<route>))
  block(ret)
    for (ele in forwarding-table)
      if (ip-in-cidr?(ele.cidr, destination))
        ret(ele)
      end;
    end;
  end;
end;

define method find-adapter-for-forwarding (ip-layer :: <ip-layer>, destination-address :: <ipv4-address>)
 => (res :: <adapter>, next-hop :: <ipv4-address>);
  let direct-route = find-route(ip-layer.routes, destination-address);
  unless (direct-route)
    error("No route to host")
  end;
  if (instance?(direct-route, <connected-route>))
    values(direct-route.adapter, destination-address);
  else
    let route = find-route(ip-layer.routes, direct-route.next-hop);
    if (instance?(route, <connected-route>))
      values(route.adapter, direct-route.next-hop)
    else
      error("No direct route to next-hop");
    end;
  end;
end;

define open generic ip-protocol (object :: <ip-socket>) => (res :: <integer>);
define class <ip-socket> (<socket>)
  constant slot ip-protocol :: <integer>, init-keyword: protocol:;
  constant slot listen-address :: false-or(<ipv4-address>) = #f, init-keyword: listen-address:;
end;

define method create-socket (ip-layer :: <ip-layer>,
                             protocol :: <integer>,
                             #key ip-address)
 => (res :: <ip-socket>)
  let source-address = ip-address | ip-layer.default-ip-address;
  let socket = make(<ip-socket>,
                    protocol: protocol,
                    listen-address: source-address);
  let template-frame = make(<ipv4-frame>,
                            protocol: protocol,
                            source-address: source-address);
  socket.completer := make(<completer>,
                           template-frame: template-frame);
  socket.demultiplexer-output
    := create-output-for-filter(ip-layer.demultiplexer,
                                format-to-string("(ipv4.destination-address = %s) & (ipv4.protocol = %s)",
                                                 source-address, protocol));
  connect(socket.demultiplexer-output, socket.decapsulator);
  connect(socket.completer, ip-layer.fan-in);
  socket;
end;

define method send (ip-socket :: <ip-socket>, destination :: <ipv4-address>, payload :: <container-frame>)
  let frame = make(<ipv4-frame>,
                   destination-address: destination,
                   payload: payload);
  push-data-aux(ip-socket.completer.the-input, ip-socket.completer, frame);
end;


define generic ip-socket (object :: <icmp-handler>) => (res :: <ip-socket>);
define generic ip-socket-setter (value :: <ip-socket>, object :: <icmp-handler>) => (res :: <ip-socket>);

define class <icmp-handler> (<filter>)
  slot ip-socket :: <ip-socket>;
end;

define method push-data-aux (input :: <push-input>,
                             node :: <icmp-handler>,
                             frame :: <container-frame>)
  //format-out("ICMP Handler received %=\n", frame);
  if (frame.type = 8 & frame.code = 0)
    let response = make(<icmp-frame>,
                        type: 0,
                        code: 0,
                        payload: frame.payload);
    send(node.ip-socket, frame.parent.source-address, response)
  end;
end;
define generic icmp-handler (object :: <icmp-over-ip-adapter>) => (res :: <icmp-handler>);

define class <icmp-over-ip-adapter> (<adapter>)
  constant slot ip-layer :: <ip-layer>, required-init-keyword: ip-layer:;
  constant slot icmp-handler :: <icmp-handler>, required-init-keyword: icmp-handler:;
end;

define method initialize (icmp-over-ip :: <icmp-over-ip-adapter>,
                          #rest rest, #key, #all-keys);
  let icmp-socket = create-socket(icmp-over-ip.ip-layer, 1);
  connect(icmp-socket.decapsulator, icmp-over-ip.icmp-handler);
  icmp-over-ip.icmp-handler.ip-socket := icmp-socket;
end;

define generic arp-table (object :: <arp-handler>) => (res :: <vector-table>);
define generic table-lock (object :: <arp-handler>) => (res :: <lock>);
define class <arp-handler> (<filter>)
  constant slot arp-table :: <vector-table> = make(<vector-table>);
  constant slot table-lock :: <lock> = make(<lock>);
  slot send-socket :: <socket>;
  slot ip-send-socket :: <ethernet-socket>;
end;

define generic original-request (object :: <outstanding-arp-request>) => (res :: <frame>);
define generic destination (object :: <outstanding-arp-request>) => (res :: <mac-address>);
define open generic timer (object :: <outstanding-arp-request>) => (res :: <timer>);
define open generic timer-setter (value :: <timer>, object :: <outstanding-arp-request>) => (res :: <timer>);
define open generic counter (object :: <outstanding-arp-request>) => (res :: <object>);
define open generic counter-setter (value :: <object>, object :: <outstanding-arp-request>) => (res :: <object>);
define open generic outstanding-packets (object :: <outstanding-arp-request>) => (res :: <list>);
define open generic outstanding-packets-setter (value :: <list>, object :: <outstanding-arp-request>) => (res :: <list>);
define open generic ip-address (object :: <arp-entry>) => (res :: <ipv4-address>);
define abstract class <arp-entry> (<object>)
  constant slot ip-address :: <ipv4-address>, required-init-keyword: ip-address:;
end;

define class <outstanding-arp-request> (<arp-entry>)
  constant slot original-request :: <frame>, required-init-keyword: request:;
  constant slot destination :: <mac-address>, required-init-keyword: destination:;
  slot timer :: <timer>;
  slot counter = 0;
  slot outstanding-packets :: <list>, required-init-keyword: outstanding-packets:;
end;

define generic arp-mac-address (object :: <known-arp-entry>) => (res :: <mac-address>);
define abstract class <known-arp-entry> (<arp-entry>)
  constant slot arp-mac-address :: <mac-address>, required-init-keyword: mac-address:;
end;

define class <static-arp-entry> (<known-arp-entry>)
end;

define class <advertised-arp-entry> (<static-arp-entry>)
end;

define open generic arp-timestamp (object :: <dynamic-arp-entry>) => (res :: <date>);
define class <dynamic-arp-entry> (<known-arp-entry>)
  constant slot arp-timestamp :: <date> = current-date()
end;

define method try-again (request :: <outstanding-arp-request>, handler :: <arp-handler>)
  with-lock(handler.table-lock)
    if (request.counter > 3)
      remove-key!(handler.arp-table, request.ip-address);
    else
      send(handler.send-socket, request.destination, request.original-request);
      request.timer := make(<timer>, in: 5, event: curry(try-again, request, handler));
      request.counter := request.counter + 1;
    end
  end
end;
   
define method push-data-aux (input :: <push-input>,
                             node :: <arp-handler>,
                             frame :: <container-frame>)
  if (frame.operation = 1
      & frame.target-mac-address = mac-address("00:00:00:00:00:00"))
    let arp-entry = element(node.arp-table, frame.target-ip-address, default: #f);
    if (arp-entry & instance?(arp-entry, <advertised-arp-entry>))
      let arp-response = make(<arp-frame>,
                              operation: 2,
                              target-mac-address: frame.source-mac-address,
                              target-ip-address: frame.source-ip-address,
                              source-mac-address: arp-entry.arp-mac-address,
                              source-ip-address: arp-entry.ip-address);
      send(node.send-socket, frame.source-mac-address, arp-response);
    end;
  elseif (frame.operation = 2)
    with-lock(node.table-lock)
      let old-entry = element(node.arp-table, frame.source-ip-address, default: #f);
      if (instance?(old-entry, <outstanding-arp-request>))
        cancel(old-entry.timer);
        do(curry(send, node.ip-send-socket, frame.source-mac-address), old-entry.outstanding-packets);
      end;
      maybe-add-response-to-table(old-entry, node, frame);
    end
  end;
end;

define method add-response-to-table (node :: <arp-handler>, frame :: <arp-frame>)
  node.arp-table[frame.source-ip-address]
    := make(<dynamic-arp-entry>,
            ip-address: frame.source-ip-address,
            mac-address: frame.source-mac-address);
end;

define method maybe-add-response-to-table
    (old-entry == #f, node :: <arp-handler>, frame :: <arp-frame>)
end;

define method maybe-add-response-to-table 
    (old-entry :: <outstanding-arp-request>, node :: <arp-handler>, frame :: <arp-frame>)
  add-response-to-table(node, frame);
end;

define method maybe-add-response-to-table
    (old-entry :: <static-arp-entry>, node :: <arp-handler>, frame :: <arp-frame>)
  ignore(old-entry, node, frame);
end;

define method maybe-add-response-to-table
    (old-entry :: <dynamic-arp-entry>, node :: <arp-handler>, frame :: <arp-frame>)
  if (frame.source-mac-address ~= old-entry.arp-mac-address)
    format-out("ARP: IP %= moved from %= to %=\n",
               old-entry.ip-address,
               old-entry.arp-mac-address,
               frame.source-mac-address);
  end;
  add-response-to-table(node, frame)
end;



define function init-ethernet ()
  let int = make(<ethernet-interface>, name: "Xtreme");
  let ethernet-layer = make(<ethernet-layer>, ethernet-interface: int);
  let arp-handler = make(<arp-handler>);
/*
  arp-handler.arp-table[ipv4-address("192.168.0.23")]
    := make(<advertised-arp-entry>,
            mac-address: mac-address("00:de:ad:be:ef:00"),
            ip-address: ipv4-address("192.168.0.23"));
*/
  let ip-layer = make(<ip-layer>);
  register-route(ip-layer, make(<next-hop-route>, cidr: as(<cidr>, "0.0.0.0/0"),
                                next-hop: ipv4-address("192.168.0.1")));
  let ip-over-ethernet = make(<ip-over-ethernet-adapter>,
                              ethernet: ethernet-layer,
                              arp: arp-handler,
                              ip-layer: ip-layer,
                              ipv4-address: ipv4-address("192.168.0.24"),
                              netmask: 24);
  let icmp-handler = make(<icmp-handler>);
  let icmp-over-ip = make(<icmp-over-ip-adapter>,
                          ip-layer: ip-layer,
                          icmp-handler: icmp-handler);
  let thr = make(<thread>, function: curry(toplevel, int));
/*
  send(icmp-handler.ip-socket,
       ipv4-address("213.73.91.29"),
       make(<icmp-frame>,
            type: 8,
            code: 0,
            payload: parse-frame(<raw-frame>, as(<byte-vector>, #(#x23, #x42, #x0, #x0)))));
  send(icmp-handler.ip-socket,
       ipv4-address("212.202.174.224"),
       make(<icmp-frame>,
            type: 8,
            code: 0,
            payload: parse-frame(<raw-frame>, as(<byte-vector>, #(#x23, #x42, #x0, #x0)))));
  send(icmp-handler.ip-socket,
       ipv4-address("192.168.0.1"),
       make(<icmp-frame>,
            type: 8,
            code: 0,
            payload: parse-frame(<raw-frame>, as(<byte-vector>, #(#x23, #x42, #x0, #x0)))));

  format-out("Mac 192.168.2.1: %=\n", element(arp-handler.arp-table, ipv4-address("192.168.2.1"), default: #f));
*/
  ip-layer;
end;

