module: arp
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define class <arp-handler> (<filter>)
  constant slot arp-table :: <vector-table> = make(<vector-table>);
  constant slot table-lock :: <lock> = make(<lock>);
  slot send-socket :: <socket>;
end;

define layer arp (<layer>)
  slot arp-flow-node :: <arp-handler> = make(<arp-handler>);
  inherited property administrative-state = #"up"
end;

define method check-upper-layer? (lower :: <arp-layer>, upper :: <layer>) => (allowed? :: <boolean>);
  #f;
end;

define method check-lower-layer? (upper :: <arp-layer>, lower :: <layer>) => (allowed? :: <boolean>);
  upper.@running-state == #"down" &
    check-socket-arguments?(lower, type: <arp-frame>);
end;

define function add-advertised-arp-entry
    (arp-layer :: <arp-layer>, ip-address :: <ipv4-address>, mac-address :: <mac-address>)
  let arp-entry = make(<advertised-arp-entry>,
		       mac-address: mac-address,
		       ip-address: ip-address);
  arp-layer.arp-flow-node.arp-table[ip-address] := arp-entry;
  if (arp-layer.@running-state == #"up")
    send-gratitious-arp(arp-layer.arp-flow-node, arp-entry);
  end;
end;

define function remove-arp-entry
    (arp-layer :: <arp-layer>, ip-address :: <ipv4-address>)
  remove-key!(arp-layer.arp-flow-node.arp-table, ip-address);
end;

define method register-lower-layer (upper :: <arp-layer>, lower :: <layer>)
  register-property-changed-event(lower, #"running-state",
                                  curry(toggle-running-state, upper),
                                  owner: upper);
end;

define function toggle-running-state (upper :: <arp-layer>, event :: <property-changed-event>)
 => ();
  let property = event.property-changed-event-property;
  let lower = property.property-owner;
  if (property.property-value == #"up")
    let socket = create-socket(lower, filter-string: "arp");
    upper.arp-flow-node.send-socket := socket;
    connect(socket.socket-output, upper.arp-flow-node.the-input);
    upper.@running-state := #"up";
    send-gratitious-arps(upper.arp-flow-node);
  else
    let remove-them = list();
    for (arp-entry in upper.arp-flow-node.arp-table)
      if (instance?(arp-entry, <outstanding-arp-request>))
        cancel(arp-entry.timer);
        remove-them := pair(arp-entry, remove-them);
      end;
    end;
    do(curry(remove-key!, upper.arp-flow-node.arp-table), remove-them);
    upper.@running-state := #"down";
  end;
end;

define constant $broadcast-ethernet-address = mac-address("ff:ff:ff:ff:ff:ff");

define function arp-resolve (arp :: <arp-layer>, destination :: <ipv4-address>, clos :: <function>) => ();
  if (arp.@running-state == #"down")
    error("arp layer down!");
  end;
  let arp-entry = element(arp.arp-flow-node.arp-table, destination, default: #f);
  if (instance?(arp-entry, <known-arp-entry>))
    clos(arp-entry.arp-mac-address);
  else
    let arp-handler = arp.arp-flow-node;
    with-lock(arp-handler.table-lock)
      if (arp-entry)
        arp-entry.outstanding-closures := add!(arp-entry.outstanding-closures, clos);
      else
        let from-addr = arp.lower-layers[0].@mac-address;
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
        sendto(arp-handler.send-socket, $broadcast-ethernet-address, arp-request);
        let outstanding-request = make(<outstanding-arp-request>,
                                       handler: arp-handler,
                                       request: arp-request,
                                       destination: $broadcast-ethernet-address,
                                       ip-address: destination,
                                       outstanding-closures: list(clos));
        let timer* = make(<timer>, in: 5, event: curry(try-again, outstanding-request, arp-handler));
        outstanding-request.timer := timer*;
        arp-handler.arp-table[destination] := outstanding-request;
        arp-entry := outstanding-request;
      end;
    end;
  end;
end;

define abstract class <arp-entry> (<object>)
  constant slot ip-address :: <ipv4-address>, required-init-keyword: ip-address:;
end;

define class <outstanding-arp-request> (<arp-entry>)
  constant slot original-request :: <frame>, required-init-keyword: request:;
  constant slot destination :: <mac-address>, required-init-keyword: destination:;
  slot timer :: <timer>;
  slot counter = 0;
  slot outstanding-closures :: <list>, required-init-keyword: outstanding-closures:;
end;

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

define function print-arp-table (stream :: <stream>, layer :: <arp-layer>)
  for (arp in layer.arp-flow-node.arp-table)
    format(stream, "%=\n", arp);
  end;
end;

define class <dynamic-arp-entry> (<known-arp-entry>)
  constant slot arp-timestamp :: <date> = current-date()
end;

define method try-again (request :: <outstanding-arp-request>, handler :: <arp-handler>)
  with-lock(handler.table-lock)
    if (request.counter > 3)
      remove-key!(handler.arp-table, request.ip-address);
    else
      sendto(handler.send-socket, request.destination, request.original-request);
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
      sendto(node.send-socket, frame.source-mac-address, arp-response);
    end;
  elseif (frame.operation = #"arp-response")
    with-lock(node.table-lock)
      let old-entry = element(node.arp-table, frame.source-ip-address, default: #f);
      if (instance?(old-entry, <outstanding-arp-request>))
        cancel(old-entry.timer);
	for (out in old-entry.outstanding-closures)
	  out(frame.source-mac-address);
	end;
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
  //XXX: print warning?
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

define function send-gratitious-arps (arp-handler :: <arp-handler>)
  for (arp-entry in arp-handler.arp-table)
    if (instance?(arp-entry, <advertised-arp-entry>))
      send-gratitious-arp(arp-handler, arp-entry)
    end;
  end;
end;

define function send-gratitious-arp (arp-handler :: <arp-handler>, arp-entry :: <advertised-arp-entry>)
  let arp-frame = make(<arp-frame>,
		       operation: #"arp-request",
		       source-mac-address: arp-entry.arp-mac-address,
		       source-ip-address: arp-entry.ip-address,
		       target-mac-address: mac-address("00:00:00:00:00:00"),
		       target-ip-address: arp-entry.ip-address);
  sendto(arp-handler.send-socket, $broadcast-ethernet-address, arp-frame);
end;

