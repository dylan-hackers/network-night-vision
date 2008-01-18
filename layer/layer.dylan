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

// Every layer handles frames of a certain type.  This g.f. returns the type.
define open generic frame-type-for-layer (layer :: <layer>) => (frame-type :: subclass(<frame>));

define abstract class <layer> (<object>)
  constant slot fan-in :: <fan-in> = make(<fan-in>);
  constant slot fan-out :: <fan-out> = make(<fan-out>);
  constant slot demultiplexer :: <demultiplexer> = make(<demultiplexer>);
  constant slot sockets :: <collection> = make(<stretchy-vector>);
end;

define open generic demultiplexer-output (object :: <socket>) => (res :: <object>);
define open generic demultiplexer-output-setter (value :: <object>, object :: <socket>) => (res :: <object>);
define open generic decapsulator (object :: <socket>) => (res :: <decapsulator>);
define open generic completer (object :: <socket>) => (res :: <completer>);
define open generic completer-setter (value :: <completer>, object :: <socket>) => (res :: <completer>);

define class <raw-socket> (<object>)
  constant slot socket-layer :: <layer>, required-init-keyword: layer:;
end;

define method connect (socket :: <raw-socket>, input :: <push-input>)
  connect(socket.socket-layer.fan-out, input);
end;

define method connect (socket :: <raw-socket>, input :: <single-push-input-node>)
  connect(socket.socket-layer.fan-out, input.the-input);
end;

define method disconnect (false == #f, object :: <object>)
  // catch-all: already disconnected
end;

define method disconnect (object :: <object>, false == #f)
  // catch-all: already disconnected
end;

define method disconnect (socket :: <raw-socket>, input :: <push-input>)
  disconnect(socket.socket-layer.fan-out, input);
end;

define method disconnect (socket :: <raw-socket>, input :: <single-push-input-node>)
  disconnect(socket.socket-layer.fan-out, input.the-input);
end;

define method connect (node :: <single-push-output-node>, socket :: <raw-socket>)
  connect(node.the-output, socket.socket-layer.fan-in);
end;

define method connect (node :: <push-output>, socket :: <raw-socket>)
  connect(node, socket.socket-layer.fan-in);
end;

define method disconnect (node :: <push-output>, socket :: <raw-socket>)
  disconnect(node, socket.socket-layer.fan-in);
end;

define method disconnect (node :: <single-push-output-node>, socket :: <raw-socket>)
  disconnect(node.the-output, socket.socket-layer.fan-in);
end;
define abstract class <socket> (<object>)
  constant slot decapsulator :: <decapsulator> = make(<decapsulator>);
  slot demultiplexer-output;
  slot completer :: <completer>;
end;

define class <filter-socket> (<socket>)
end;

define method connect (node :: <single-push-output-node>, socket :: <filter-socket>)
  connect(node.the-output, socket.completer.the-input);
end;

define method connect (node :: <push-output>, socket :: <filter-socket>)
  connect(node, socket.completer.the-input);
end;

define method disconnect (node :: <push-output>, socket :: <filter-socket>)
  disconnect(node, socket.completer.the-input);
end;

define method disconnect (node :: <single-push-output-node>, socket :: <filter-socket>)
  disconnect(node.the-output, socket.completer.the-input);
end;

define method connect (socket :: <filter-socket>, input :: <push-input>)
  connect(socket.decapsulator.the-output, input);
end;

define method connect (socket :: <filter-socket>, input :: <single-push-input-node>)
  connect(socket.decapsulator.the-output, input.the-input);
end;

define method disconnect (socket :: <filter-socket>, input :: <push-input>)
  disconnect(socket.decapsulator.the-output, input);
end;

define method disconnect (socket :: <filter-socket>, input :: <single-push-input-node>)
  disconnect(socket.decapsulator.the-output, input.the-input);
end;

define method create-filter-socket (layer :: <layer>, 
                                    filter-key-value-pairs,
                                    completer-key-value-pairs)
 => (socket :: <filter-socket>);
  let socket = make(<filter-socket>);
  let frame-type = frame-type-for-layer(layer);
  let template-frame = apply(make, frame-type, completer-key-value-pairs);
  socket.completer := make(<completer>, template-frame: template-frame);
  socket.demultiplexer-output
    := create-output-for-filter(layer.demultiplexer,
                                apply(build-frame-filter, frame-type, filter-key-value-pairs));
  connect(socket.demultiplexer-output, socket.decapsulator);
  connect(socket.completer, layer.fan-in);
  socket;
end;

define method close-socket (socket :: <filter-socket>) => ();
  disconnect(socket.decapsulator.the-output, socket.decapsulator.the-output.connected-input);
  disconnect(socket.demultiplexer-output, socket.decapsulator.the-input);
  disconnect(socket.completer.the-output, socket.completer.the-output.connected-input);
  disconnect(socket.completer.the-input.connected-output, socket.completer.the-input);
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
  connect(layer.ethernet-interface, layer.fan-out);
  connect(layer.fan-out, layer.demultiplexer);
end;

define method frame-type-for-layer (layer :: <ethernet-layer>)
 => (type == <ethernet-frame>)
 <ethernet-frame>
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

define method create-raw-socket (layer :: <ethernet-layer>)
 => (socket :: <raw-socket>)
  make(<raw-socket>, layer: layer);
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
  slot v4-address :: <ipv4-address>, required-init-keyword: ipv4-address:;
  slot netmask :: <integer>, required-init-keyword: netmask:;
  slot ip-send-socket :: <ethernet-socket>;
end;

define method send (socket :: <ip-over-ethernet-adapter>, destination :: <ipv4-address>, payload :: <container-frame>);
  if (destination = broadcast-address(make(<cidr>, network-address: socket.v4-address, netmask: socket.netmask)))
    send(socket.ip-send-socket, $broadcast-ethernet-address, payload);
  else
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
                                   instance?(x, <known-arp-entry>) &
                                     (x.arp-mac-address = from-addr)
                                 end);
          let arp-request = make(<arp-frame>,
                                 operation: #"arp-request",
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
end;

define constant $broadcast-ethernet-address = mac-address("ff:ff:ff:ff:ff:ff");

define function set-ip-address (ip-over-ethernet :: <ip-over-ethernet-adapter>, address :: <ipv4-address>, netmas :: <integer>)
  unregister-adapter(ip-over-ethernet.ip-layer, ip-over-ethernet);
  remove-key!(ip-over-ethernet.arp-handler.arp-table, ip-over-ethernet.v4-address);
  ip-over-ethernet.v4-address := address;
  ip-over-ethernet.netmask := netmas;
  reconfigure-ip-address(ip-over-ethernet);
end;

define function reconfigure-ip-address (ip-over-ethernet :: <ip-over-ethernet-adapter>)
  unless (ip-over-ethernet.v4-address = ipv4-address("0.0.0.0"))
    ip-over-ethernet.arp-handler.arp-table[ip-over-ethernet.v4-address]
      := make(<advertised-arp-entry>,
              ip-address: ip-over-ethernet.v4-address,
              mac-address: ip-over-ethernet.ethernet-layer.default-mac-address);
  end;
  register-adapter(ip-over-ethernet.ip-layer, ip-over-ethernet);
  ip-over-ethernet.ip-layer.default-ip-address := ip-over-ethernet.v4-address;
end;

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


  let ip-socket = create-socket(ip-over-ethernet.ethernet-layer, #x800);
  let ip-broadcast-socket = create-socket(ip-over-ethernet.ethernet-layer,
                                          #x800,
                                          mac-address: $broadcast-ethernet-address);
  ip-over-ethernet.ip-send-socket := ip-socket;
  ip-over-ethernet.arp-handler.ip-send-socket := ip-socket;
  let ipv4-fan-in = make(<fan-in>);
  connect(ip-socket.decapsulator, ipv4-fan-in);
  connect(ip-broadcast-socket.decapsulator, ipv4-fan-in);
  connect(ipv4-fan-in, ip-over-ethernet.ip-layer.reassembler);
  reconfigure-ip-address(ip-over-ethernet);
end; 


define open generic fragmented-packets (object :: <ip-reassembler>) => (res :: <vector-table>);

define class <ip-reassembler> (<filter>)
  constant slot fragmented-packets :: <vector-table> = make(<vector-table>);
end;

define inline function generate-assembly-id (ip-frame :: <ipv4-frame>)
 => (res :: <vector>)
  concatenate(ip-frame.source-address.data,
              ip-frame.destination-address.data,
              assemble-frame-as(<2byte-big-endian-unsigned-integer>, ip-frame.identification));
end;


define generic first-packet (obj :: <frag-packet>) => (res);
define generic payloads (obj :: <frag-packet>) => (res :: <stretchy-vector>);
define generic next-fragment-offset (obj :: <frag-packet>) => (res :: <integer>);
define generic next-fragment-offset-setter (value :: <integer>, obj :: <frag-packet>) => (res :: <integer>);
define generic timeout (obj :: <frag-packet>) => (res);
define generic timeout-setter (value, obj :: <frag-packet>) => (res);

define class <frag-packet> (<object>)
  constant slot first-packet, required-init-keyword: first-packet:;
  constant slot payloads :: <stretchy-vector> = make(<stretchy-vector>);
  slot next-fragment-offset :: <integer> = 0, init-keyword: next-offset:;
  slot timeout, required-init-keyword: timeout:;
end;

//XXX: this really should take care of out-of-order segments
// and don't set the precondition that IP fragments arrive
// in correct order
define method push-data-aux (input :: <push-input>,
                             node :: <ip-reassembler>,
                             frame :: <ipv4-frame>)
  if (frame.fragment-offset = 0)
    if (frame.more-fragments = 0)
      //fast path, just pass frame
      push-data(node.the-output, frame);
    else
      let packet-id = generate-assembly-id(frame);
      let timer = make(<timer>, in: 300, event: curry(remove-key!, node.fragmented-packets, packet-id));
      node.fragmented-packets[packet-id]
        := make(<frag-packet>,
                first-packet: frame,
                timeout: timer,
                next-offset: byte-offset(byte-offset(frame-size(frame.payload))));
    end;
  else
    let packet-id = generate-assembly-id(frame);
    let frag-packet = element(node.fragmented-packets, packet-id, default: #f);
    if (frag-packet)
      if (frag-packet.next-fragment-offset = frame.fragment-offset)
        add!(frag-packet.payloads, frame.payload.packet);
        frag-packet.next-fragment-offset
          := frag-packet.next-fragment-offset + byte-offset(byte-offset(frame-size(frame.payload)));
        cancel(frag-packet.timeout);
        frag-packet.timeout
          := make(<timer>, in: 300, event: curry(remove-key!, node.fragmented-packets, packet-id));
      else
        format-out("Received out of order IP Fragment (%d, expected %d)\n",
                   frame.fragment-offset, frag-packet.next-fragment-offset);
      end;
      if (frame.more-fragments = 0)
        let fp = frag-packet.first-packet;
        fp.cache.payload := parse-frame(fp.payload-type,
                                        reduce(concatenate, fp.payload.packet, frag-packet.payloads),
                                        parent: fp);
        push-data(node.the-output, fp);
        cancel(frag-packet.timeout);
        remove-key!(node.fragmented-packets, packet-id);
      end;
    else
      format-out("Received out of order IP Fragment (offset %d, but didn't receive the first yet)\n",
                 frame.fragment-offset);
    end;
  end;
end;

define open generic send-socket (object :: <object>) => (res);
define open generic send-socket-setter (value :: <object>, object :: <object>) => (res);
define generic default-ip-address (object :: <layer>) => (res :: <ipv4-address>);
define generic default-ip-address-setter (value :: <ipv4-address>, object :: <layer>) => (res :: <ipv4-address>);
define open generic adapters (object :: <ip-layer>) => (res);
define open generic routes (object :: <ip-layer>) => (res);
define open generic reassembler (object :: <ip-layer>) => (res);

define class <ip-layer> (<layer>)
  slot send-socket :: type-union(<socket>, <adapter>);
  constant slot adapters = make(<stretchy-vector>);
  slot default-ip-address :: <ipv4-address>;
  constant slot routes = make(<stretchy-vector>);
  constant slot reassembler = make(<ip-reassembler>);
  slot raw-input;
end;

define method frame-type-for-layer (layer :: <ip-layer>)
 => (type == <ipv4-frame>)
 <ipv4-frame>
end;

define class <route> (<object>)
  constant slot cidr :: <cidr>, required-init-keyword: cidr:;
end;

define generic next-hop (object :: <next-hop-route>) => (res :: <ipv4-address>);

define class <next-hop-route> (<route>)
  constant slot next-hop :: <ipv4-address>, required-init-keyword: next-hop:;
end;

define method print-object (object :: <next-hop-route>, stream :: <stream>) => ()
  format(stream, "%= -> %s", object.cidr, object.next-hop);
end;
define generic adapter (object :: <connected-route>) => (res :: <adapter>);
define class <connected-route> (<route>)
  constant slot adapter :: <adapter>, required-init-keyword: adapter:;
end;

define method print-object (object :: <connected-route>, stream :: <stream>) => ()
  format(stream, "%= -> %=", object.cidr, object.adapter);
end;

define function print-forwarding-table (stream :: <stream>, ip-layer :: <ip-layer>)
  for (route in ip-layer.routes)
    format(stream, "%=\n", route);
  end;
end;
define method register-route (ip :: <ip-layer>, route :: <route>)
  add!(ip.routes, route);
  sort!(ip.routes, test: method(x, y) x.cidr.cidr-netmask > y.cidr.cidr-netmask end)
end;

//implicit assumptions made: *frame has no ip-options (header-length = 5)
define method initialize (ip-layer :: <ip-layer>,
                          #rest rest, #key, #all-keys);
  let cls = make(<closure-node>,
                 closure: method(x)
                            let (adapter, next-hop)
                              = find-adapter-for-forwarding(ip-layer, x.destination-address);
                            /* let mtu = find-mtu-for-destination(adapter, x.destination-address) * 8;
                            let unparsed-ip = assemble-frame(x);
                            let full-payload = unparsed-ip.payload.packet;
                            let data-size = frame-size(x.payload);
                            if (mtu < data-size)
                              x.more-fragments := 1;
                              for (i from 0 below data-size - mtu by mtu,
                                   j from 0)
                                x.payload := parse-frame(<raw-frame>, subsequence(full-payload, start: i, length: mtu));
                                let ip-frame = assemble-frame(x);
                                fixup!(ip-frame);
                                send(adapter, next-hop, ip-frame);
                                x.fragment-offset := byte-offset(byte-offset((j + 1) * mtu));
                              end;
                            end;
                            x.more-fragments := 0;
                            x.payload := parse-frame(<raw-frame>, subsequence(full-payload,
                                                                              start: x.fragment-offset * 8 * 8,
                                                                              length: modulo(data-size, mtu)));
                            x.total-length := #f; */
                            //let ip-frame = assemble-frame(x);
                            //fixup!(ip-frame);
                            send(adapter, next-hop, x);
                          end);
  connect(ip-layer.fan-in, cls);
  connect(ip-layer.reassembler, ip-layer.demultiplexer);
  ip-layer.raw-input := create-input(ip-layer.fan-in);
end;

define method find-mtu-for-destination (adapter :: <ip-over-ethernet-adapter>, destination :: <ipv4-address>)
 => (res :: <integer>)
  1480;
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
  //unregister-route
  let my-cidr = make(<cidr>, netmask: adapter.netmask, network-address: adapter.v4-address);
  delete-route(ip, my-cidr);
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

define method send (ip-layer :: <ip-layer>, destination :: <ipv4-address>, payload :: <container-frame>)
  let frame = make(<ipv4-frame>,
                   destination-address: destination,
                   source-address: ip-layer.default-ip-address,
                   payload: payload);
  push-data-aux(ip-layer.raw-input, ip-layer.fan-in, frame);
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
                                if (source-address = ipv4-address("0.0.0.0"))
                                  format-to-string("ipv4.protocol = %s", protocol);
                                else
                                  format-to-string("(ipv4.destination-address = %s) & (ipv4.protocol = %s)",
                                                   source-address, protocol)
                                end);
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
  if (frame.icmp-type = 8 & frame.code = 0)
    let response = make(<icmp-frame>,
                        icmp-type: 0,
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

define method print-object (object :: <outstanding-arp-request>, stream :: <stream>) => ()
  format(stream, "? %s", object.ip-address);
end;

define method print-object (object :: <static-arp-entry>, stream :: <stream>) => ()
  format(stream, "S %s %s", object.ip-address, object.arp-mac-address);
end;

define method print-object (object :: <advertised-arp-entry>, stream :: <stream>) => ()
  format(stream, "A %s %s", object.ip-address, object.arp-mac-address);
end;
define method print-object (object :: <dynamic-arp-entry>, stream :: <stream>) => ()
  format(stream, "D %s %s", object.ip-address, object.arp-mac-address);
end;

define function print-arp-table (stream :: <stream>, arp-handler :: <arp-handler>)
  for (arp in arp-handler.arp-table)
    format(stream, "%=\n", arp);
  end;
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
  if (frame.operation = #"arp-request"
      & frame.target-mac-address = mac-address("00:00:00:00:00:00"))
    let arp-entry = element(node.arp-table, frame.target-ip-address, default: #f);
    if (arp-entry & instance?(arp-entry, <advertised-arp-entry>))
      let arp-response = make(<arp-frame>,
                              operation: #"arp-response",
                              target-mac-address: frame.source-mac-address,
                              target-ip-address: frame.source-ip-address,
                              source-mac-address: arp-entry.arp-mac-address,
                              source-ip-address: arp-entry.ip-address);
      send(node.send-socket, frame.source-mac-address, arp-response);
    end;
  elseif (frame.operation = #"arp-response")
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

define function send-gratitious-arp (arp-handler :: <arp-handler>, ip :: <ipv4-address>)
  let arp-entry = element(arp-handler.arp-table, ip, default: #f);
  if (arp-entry)
    let arp-frame = make(<arp-frame>,
                         operation: #"arp-request",
                         source-mac-address: arp-entry.arp-mac-address,
                         source-ip-address: arp-entry.ip-address,
                         target-mac-address: mac-address("00:00:00:00:00:00"),
                         target-ip-address: arp-entry.ip-address);
    send(arp-handler.send-socket, $broadcast-ethernet-address, arp-frame);
  end;
end;

/* dead code?
define function init-arp-handler (#key mac-address :: <mac-address> = mac-address("00:de:ad:be:ef:00"),
                                  ip-address :: <ipv4-address> = ipv4-address("192.168.0.69"),
                                  netmask :: <integer> = 24,
                                  interface-name :: <string> = "eth0");
  let interface = make(<ethernet-interface>, name: interface-name);
  let ethernet-layer = make(<ethernet-layer>,
                            ethernet-interface: interface,
                            default-mac-address: mac-address);
  let arp-handler = make(<arp-handler>);
  let cidr = make(<cidr>, network-address: ip-address, netmask: netmask);
  unless (broadcast-address(cidr) = ip-address)
    arp-handler.arp-table[ip-address] := make(<advertised-arp-entry>,
                                              mac-address: mac-address,
                                              ip-address: ip-address);
  end;
  let arp-socket = create-socket(ethernet-layer, #x806);
  let arp-broadcast-socket = create-socket(ethernet-layer, #x806, mac-address: $broadcast-ethernet-address);
  let arp-fan-in = make(<fan-in>);
  arp-handler.send-socket := arp-socket;
  connect(arp-socket.decapsulator, arp-fan-in);
  connect(arp-broadcast-socket.decapsulator, arp-fan-in);
  connect(arp-fan-in, arp-handler);
  send-gratitious-arp(arp-handler, ip-address);
  ethernet-layer;
end;
*/

define function build-ethernet-layer (interface-name :: <string>,
                                      #key promiscuous? :: <boolean>,
                                           mac-address :: <mac-address> = mac-address("00:de:ad:be:ef:00"));
  let int = make(<ethernet-interface>, name: interface-name, promiscuous?: promiscuous?);
  let ethernet-layer = make(<ethernet-layer>, ethernet-interface: int, default-mac-address: mac-address);
  make(<thread>, function: curry(toplevel, int));
  ethernet-layer;
end;
                                    
define function add-next-hop-route (ip-layer :: <ip-layer>, next-hop :: <ipv4-address>, cidr :: <cidr>)
  register-route(ip-layer, make(<next-hop-route>,
                                next-hop: next-hop,
                                cidr: cidr));
end;

define function delete-route (ip-layer :: <ip-layer>, mycidr :: <cidr>)
  let route = choose(method(x) x.cidr = mycidr end, ip-layer.routes);
  do(curry(remove!, ip-layer.routes), route);
end;

define function build-ip-layer (ethernet-layer,
                               #key ip-address :: false-or(<ipv4-address>),
                               default-gateway :: false-or(<ipv4-address>),
                               netmask :: <integer> = 0)
  let arp-handler = make(<arp-handler>);
  arp-handler.arp-table[ipv4-address("255.255.255.255")]
    := make(<static-arp-entry>,
            ip-address: ipv4-address("255.255.255.255"),
            mac-address: mac-address("00:00:00:00:00:00"));
  let ip-layer = make(<ip-layer>);
  let ip-over-ethernet = make(<ip-over-ethernet-adapter>,
                              ethernet: ethernet-layer,
                              arp: arp-handler,
                              ip-layer: ip-layer,
                              ipv4-address: ip-address | ipv4-address("0.0.0.0"),
                              netmask: netmask);

  if (default-gateway)
    add-next-hop-route(ip-layer, default-gateway, make(<cidr>, network-address: ipv4-address("0.0.0.0"), netmask: 0));
  end;
  if (ip-address)
    send-gratitious-arp(arp-handler, ip-address);
  end;
  //let icmp-handler = make(<icmp-handler>);
  //let icmp-over-ip = make(<icmp-over-ip-adapter>,
  //                        ip-layer: ip-layer,
  //                        icmp-handler: icmp-handler);
  values(ip-layer, ip-over-ethernet);
end;

