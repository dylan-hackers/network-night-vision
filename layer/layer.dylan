Module:    layer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define class <undefined-field-error> (<error>)
end;

define generic ethernet-fan-in (object :: <ethernet-layer>) => (res :: <fan-in>);
define generic demultiplexer (object :: <ethernet-layer>) => (res :: <demultiplexer>);
define generic ethernet-interface (object :: <ethernet-layer>) => (res :: <ethernet-interface>);
define generic ethernet-interface-setter (object :: <ethernet-interface>, object2 :: <ethernet-layer>) => (res :: <ethernet-interface>);
define generic default-mac-address (object :: <ethernet-layer>) => (res :: <mac-address>);
define generic default-mac-address-setter (object :: <mac-address>, object2 :: <ethernet-layer>) => (res :: <mac-address>);

define class <ethernet-layer> (<object>)
  constant slot ethernet-fan-in :: <fan-in> = make(<fan-in>);
  constant slot demultiplexer :: <demultiplexer> = make(<demultiplexer>);
  //slot sockets :: <collection> = make(<stretchy-vector>);
  slot ethernet-interface :: <ethernet-interface>,
    required-init-keyword: ethernet-interface:;
  slot default-mac-address :: <mac-address> = mac-address("00:de:ad:be:ef:01"),
    init-keyword: default-mac-address:;
end;

define method initialize (layer :: <ethernet-layer>,
                          #rest rest, #key, #all-keys);
  connect(layer.ethernet-fan-in, layer.ethernet-interface);
  connect(layer.ethernet-interface, layer.demultiplexer);
end;

define generic template-frame (object :: <completer>) => (res :: <frame>);
define class <completer> (<filter>)
  constant slot template-frame :: <frame>, required-init-keyword: template-frame:;
end;

define method push-data-aux (input :: <push-input>,
                             node :: <completer>,
                             frame :: <container-frame>);
  for (field in node.template-frame.fields)
    unless (field.getter(frame))
      let default-field-value = field.getter(node.template-frame);
      if (default-field-value)
        field.setter(default-field-value, frame);
      elseif (~ field.fixup-function)
        signal(make(<undefined-field-error>));
      end;
    end;
  end;
  push-data(node.the-output, frame);
end;

define open generic ethernet-type-code (object :: <ethernet-socket>) => (res :: <integer>);
define generic listen-address (object :: <ethernet-socket>) => (res :: false-or(<mac-address>));
define open generic demultiplexer-output (object :: <ethernet-socket>) => (res :: <object>);
define open generic demultiplexer-output-setter (value :: <object>, object :: <ethernet-socket>) => (res :: <object>);
define generic decapsulator (object :: <ethernet-socket>) => (res :: <decapsulator>);
define generic completer (object :: <ethernet-socket>) => (res :: <completer>);
define generic completer-setter (value :: <completer>, object :: <ethernet-socket>) => (res :: <completer>);
define class <ethernet-socket> (<object>)
  constant slot ethernet-type-code :: <integer>, init-keyword: type-code:;
  constant slot listen-address :: false-or(<mac-address>) = #f, init-keyword: listen-address:;
  slot demultiplexer-output;
  constant slot decapsulator :: <decapsulator> = make(<decapsulator>);
  slot completer :: <completer>;
end;

define method create-socket (layer :: <ethernet-layer>,
                             type-code :: <integer>,
                             #key mac-address)
 => (socket :: <ethernet-socket>);
  let source-address = mac-address | layer.default-mac-address;
  let socket = make(<ethernet-socket>,
                    type-code: type-code,
                    listen-address: source-address);
  let template-frame = make(cache-class(<ethernet-frame>),
                            type-code: type-code,
                            source-address: source-address);
  socket.completer := make(<completer>,
                           template-frame: template-frame);
  socket.demultiplexer-output
    := create-output-for-filter(layer.demultiplexer,
                                format-to-string("(ethernet.destination-address = %s) & (ethernet.type-code = %s)",
                                                 source-address, type-code));
  connect(socket.demultiplexer-output, socket.decapsulator);
  connect(socket.completer, layer.ethernet-fan-in);
  socket;
end;

define method delete-socket (socket :: <ethernet-socket>, layer :: <ethernet-layer>)
  disconnect(socket.demultiplexer-output, socket.decapsulator);
  disconnect(socket.completer, layer.ethernet-fan-in);
end;

define open generic ethernet-layer (object :: <ip-over-ethernet-adapter>) => (res :: <ethernet-layer>);
define open generic ethernet-layer-setter (value :: <ethernet-layer>, object :: <ip-over-ethernet-adapter>) => (res :: <ethernet-layer>);
define generic arp-handler (object :: <ip-over-ethernet-adapter>) => (res :: <arp-handler>);
define generic arp-handler-setter (value :: <arp-handler>, object :: <ip-over-ethernet-adapter>) => (res :: <arp-handler>);

define class <ip-over-ethernet-adapter> (<object>)
  //slot ip-layer :: <ip-layer>, required-init-keyword: ip-layer:;
  slot ethernet-layer :: <ethernet-layer>, required-init-keyword: ethernet:;
  slot arp-handler :: <arp-handler>, required-init-keyword: arp:;
  slot v4-address :: <ipv4-address>, required-init-keyword: ipv4-address:;
end;

define method initialize (ip-over-ethernet :: <ip-over-ethernet-adapter>,
                          #rest rest, #key, #all-keys);
  let ip-socket = create-socket(ip-over-ethernet.ethernet-layer, #x800);
  let arp-socket = create-socket(ip-over-ethernet.ethernet-layer, #x806);
  let arp-broadcast-socket = create-socket(ip-over-ethernet.ethernet-layer,
                                           #x806,
                                           mac-address: mac-address("ff:ff:ff:ff:ff:ff"));
  let arp-fan-in = make(<fan-in>);
  connect(arp-socket.decapsulator, arp-fan-in);
  connect(arp-broadcast-socket.decapsulator, arp-fan-in);
  //connect(ip-socket.decapsulator, ip-handler);
  //connect(ip-handler, ip-socket.completer);
  connect(arp-fan-in, ip-over-ethernet.arp-handler);
  connect(ip-over-ethernet.arp-handler, arp-socket.completer);
  ip-over-ethernet.arp-handler.ip-over-ethernet-adapter := ip-over-ethernet;
  ip-over-ethernet.arp-handler.arp-table[ip-over-ethernet.v4-address]
    := make(<advertised-arp-entry>,
            ip-address: ip-over-ethernet.v4-address,
            mac-address: ip-over-ethernet.ethernet-layer.default-mac-address);
end;

/*
define class <ip-layer> (<object>)
  slot fan-in :: <fan-in> = make(<fan-in>);
  slot demultiplexer :: <demultiplexer> = make(<demultiplexer>);
  slot routing-table;
end;
define method add-static-route (ip-layer :: <ip-layer>, cidr :: <cidr>, adapter)
end;

define method find-route (ip-layer :: <ip-layer>, destination-address :: <ipv4-address>)
 => (adapter, next-hop)
end;

define method delete-static-route (ip-layer :: <ip-layer>, cidr :: <cidr>)
end;
*/

define generic arp-table (object :: <arp-handler>) => (res :: <vector-table>);
define generic lock (object :: <arp-handler>) => (res :: <lock>);
define generic ip-over-ethernet-adapter (object :: <arp-handler>) => (res :: <ip-over-ethernet-adapter>);
define generic ip-over-ethernet-adapter-setter (value :: <ip-over-ethernet-adapter>, object :: <arp-handler>) => (res :: <ip-over-ethernet-adapter>);
define class <arp-handler> (<filter>)
  constant slot arp-table :: <vector-table> = make(<vector-table>);
  constant slot lock :: <lock> = make(<lock>);
  slot ip-over-ethernet-adapter :: <ip-over-ethernet-adapter>;
end;

define generic original-request (object :: <outstanding-arp-request>) => (res :: <frame>);
define open generic notification (object :: <outstanding-arp-request>) => (res :: <notification>);
define open generic notification-setter (value :: <notification>, object :: <outstanding-arp-request>) => (res :: <notification>);
define open generic timer (object :: <outstanding-arp-request>) => (res :: <timer>);
define open generic timer-setter (value :: <timer>, object :: <outstanding-arp-request>) => (res :: <timer>);
define open generic counter (object :: <outstanding-arp-request>) => (res :: <object>);
define open generic counter-setter (value :: <object>, object :: <outstanding-arp-request>) => (res :: <object>);

define abstract class <arp-entry> (<object>)
  constant slot ip-address :: <ipv4-address>, required-init-keyword: ip-address:;
end;

define class <outstanding-arp-request> (<arp-entry>)
  constant slot original-request :: <frame>, required-init-keyword: request:;
  slot notification :: <notification>;
  slot timer :: <timer>;
  slot counter = 0;
end;

define abstract class <known-arp-entry> (<arp-entry>)
  constant slot arp-mac-address :: <mac-address>, required-init-keyword: mac-address:;
end;

define class <static-arp-entry> (<known-arp-entry>)
end;

define class <advertised-arp-entry> (<static-arp-entry>)
end;

define class <dynamic-arp-entry> (<known-arp-entry>)
  constant slot timestamp :: <date> = current-date()
end;

define method try-again (request :: <outstanding-arp-request>, handler :: <arp-handler>)
  with-lock(handler.lock)
    if (request.counter > 3)
      release-all(request.notification)
    else
      push-data(handler.the-output, request.original-request);
      request.timer := make(<timer>, in: 5, event: curry(try-again, request, handler));
      request.counter := request.counter + 1;
    end
  end
end;

define method initialize (outstanding-arp-request :: <outstanding-arp-request>,
                          #rest rest, #key handler :: <arp-handler>, #all-keys)
  outstanding-arp-request.notification := make(<notification>, lock: handler.lock);
end;
   
define method push-data-aux (input :: <push-input>,
                             node :: <arp-handler>,
                             frame :: <container-frame>)
  format-out("received arp frame %=\n", frame);
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
      push-data(node.the-output, make(<ethernet-frame>,
                                      payload: arp-response,
                                      destination-address: frame.source-mac-address));
    end;
  elseif (frame.operation = 2)
    with-lock(node.lock)
      let old-entry = element(node.arp-table, frame.source-ip-address, default: #f);
      maybe-add-response-to-table(old-entry, node, frame)
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
  add-response-to-table(node, frame)
end;

define method maybe-add-response-to-table 
    (old-entry :: <outstanding-arp-request>, node :: <arp-handler>, frame :: <arp-frame>)
  cancel(old-entry.timer);
  add-response-to-table(node, frame);
  release-all(old-entry.notification);
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

define method find-mac-address (arp-handler :: <arp-handler>, ip :: <ipv4-address>)
 => (res :: false-or(<mac-address>))
  let arp-entry = element(arp-handler.arp-table, ip, default: #f);
  if (instance?(arp-entry, <known-arp-entry>))
    arp-entry.arp-mac-address;
  else
    with-lock(arp-handler.lock)
      unless(arp-entry)
        let arp-request = make(<arp-frame>,
                               operation: 1,
                               source-mac-address: arp-handler.ip-over-ethernet-adapter.ethernet-layer.default-mac-address,
                               source-ip-address: arp-handler.ip-over-ethernet-adapter.v4-address,
                               target-ip-address: ip,
                               target-mac-address: mac-address("00:00:00:00:00:00"));
        let ethernet-frame = make(<ethernet-frame>,
                                  destination-address: mac-address("ff:ff:ff:ff:ff:ff"),
                                  payload: arp-request);
        push-data(arp-handler.the-output, ethernet-frame);
        let outstanding-request = make(<outstanding-arp-request>,
                                       handler: arp-handler,
                                       request: ethernet-frame,
                                       ip-address: ip);
        let timer* = make(<timer>, in: 5, event: curry(try-again, outstanding-request, arp-handler));
        outstanding-request.timer := timer*;
        arp-handler.arp-table[ip] := outstanding-request;
        arp-entry := outstanding-request;
      end;
      wait-for(arp-entry.notification);
      let entry = element(arp-handler.arp-table, ip, default: #f);
      if (entry & instance?(entry, <known-arp-entry>))
        entry.arp-mac-address;
      else
        remove-key!(arp-handler.arp-table, ip);
        #f
      end;
    end;
  end;
end;


begin
  let int = make(<ethernet-interface>, name: "NetXtreme");
  let ethernet-layer = make(<ethernet-layer>, ethernet-interface: int);
  let arp-handler = make(<arp-handler>);
  arp-handler.arp-table[ipv4-address("192.168.0.23")]
    := make(<advertised-arp-entry>,
            mac-address: mac-address("00:de:ad:be:ef:00"),
            ip-address: ipv4-address("192.168.0.23"));
  let ip-over-ethernet = make(<ip-over-ethernet-adapter>,
                              ethernet: ethernet-layer,
                              arp: arp-handler,
                              ipv4-address: ipv4-address("192.168.0.24"));
  let thr = make(<thread>, function: curry(toplevel, int));
  //format-out("Mac 192.168.0.1: %=\n", find-mac-address(arp-handler, ipv4-address("192.168.0.1")));
  sleep(1200);
end;

