module: ip-over-ethernet
synopsis: 
author: 
copyright: 

define layer ip-over-ethernet (<ip-adapter-layer>)
  property arp-handler :: <layer>;
end;

define method initialize-layer (layer :: <ip-over-ethernet-layer>, #key, #all-keys) => ()
  register-property-changed-event(layer, #"arp-handler",
                                  curry(arp-handler-changed, layer));
  register-property-changed-event(layer, #"ip-address",
                                  curry(ip-address-changed, layer));
  register-property-changed-event(layer, #"running-state",
				  curry(running-state-changed, layer));
  register-property-changed-event(layer, #"administrative-state",
				  curry(check-ready-for-up-or-down?, layer));
end;

define function arp-handler-changed
    (layer :: <ip-over-ethernet-layer>, event :: <property-changed-event>)
  if (layer.@running-state == #"up")
    remove-arp-entry(event.property-changed-event-old-value,
		     layer.@ip-address.cidr-network-address);
    if (property-set?(event.property-changed-event-property.property-value))
      add-advertised-arp-entry(event.property-changed-event-property.property-value,
			       layer.@ip-address.cidr-network-address,
			       layer.lower-layers[0].@mac-address);
    end;
  end;
  check-ready-for-up-or-down?(layer);
end;

define function ip-address-changed
    (layer :: <ip-over-ethernet-layer>, event :: <property-changed-event>)
  if (layer.@running-state == #"up")
    remove-arp-entry(layer.@arp-handler,
		     event.property-changed-event-old-value);
    if (property-set?(event.property-changed-event-property.property-value))
      add-advertised-arp-entry(layer.@arp-handler,
			       event.property-changed-event-property.property-value.cidr-network-address,
			       
			       layer.lower-layers[0].@mac-address);
    end;
  end;
  check-ready-for-up-or-down?(layer);
end;

define function mac-address-changed
    (layer :: <ip-over-ethernet-layer>, event :: <property-changed-event>)
  if (layer.@running-state == #"up")
    remove-arp-entry(layer.@arp-handler,
		     layer.@ip-address.cidr-network-address);
    add-advertised-arp-entry(layer.@arp-handler,
			     layer.@ip-address.cidr-network-address,
			     layer.lower-layers[0].@mac-address);
  end;
end;

define function check-ready-for-up-or-down?
    (layer :: <ip-over-ethernet-layer>, #rest args)
  layer.@running-state :=
    if (property-set?(layer.@arp-handler)
	  & property-set?(layer.@ip-address)
	  & (layer.lower-layers.size == 1)
	  & layer.@administrative-state == #"up"
	  & layer.lower-layers[0].@running-state == #"up")
      #"up"
    else
      #"down"
    end;
end;

define function running-state-changed
    (layer :: <ip-over-ethernet-layer>, event :: <property-changed-event>)
  if (event.property-changed-event-property.property-value == #"up")
    add-advertised-arp-entry(layer.@arp-handler,
			     layer.@ip-address.cidr-network-address,
			     layer.lower-layers[0].@mac-address);
  elseif (event.property-changed-event-old-value == #"up")
    remove-arp-entry(layer.@arp-handler,
		     layer.@ip-address.cidr-network-address);
  end
end;

define method check-upper-layer? (lower :: <ip-over-ethernet-layer>, upper :: <layer>) => (allowed? :: <boolean>);
  #t;
end;

define method check-lower-layer? (upper :: <ip-over-ethernet-layer>, lower :: <layer>) => (allowed? :: <boolean>);
  upper.lower-layers.size == 0 &
    check-socket-arguments?(lower, type: <ipv4-frame>);
end;

define method check-socket-arguments? (layer :: <ip-over-ethernet-layer>, #key type) => (res :: <boolean>)
  type == <ipv4-frame>
end;

define method register-lower-layer (upper :: <ip-over-ethernet-layer>, lower :: <layer>)
  register-property-changed-event(lower, #"running-state",
				  curry(check-ready-for-up-or-down?, upper),
				  owner: upper);
  register-property-changed-event(lower, #"mac-address",
				  curry(mac-address-changed, upper),
				  owner: upper);
end;

define method deregister-lower-layer (upper :: <ip-over-ethernet-layer>, lower :: <layer>)
  do(close-socket, upper.sockets);
  check-ready-for-up-or-down?(upper);
end;

define class <ip-over-ethernet-socket> (<socket>)
  constant slot lower-socket :: <socket>, required-init-keyword: lower-socket:;
end;

define method create-socket (layer :: <ip-over-ethernet-layer>, #key type, #all-keys)
 => (res :: <ip-over-ethernet-socket>)
  unless(layer.@running-state == #"up")
    error("Layer down");
  end;
  let filter = "ipv4";
  let socket = create-socket(layer.lower-layers[0], filter-string: filter);
  make(<ip-over-ethernet-socket>, owner: layer, lower-socket: socket);
end;

define method socket-input (socket :: <ip-over-ethernet-socket>) => (res :: <input>)
  socket.lower-socket.socket-input
end;
define method socket-output (socket :: <ip-over-ethernet-socket>) => (res :: <output>)
  socket.lower-socket.socket-output;
end;

define method close-socket (socket :: <ip-over-ethernet-socket>)
  next-method();
  close-socket(socket.lower-socket);
end;

define method sendto (socket :: <ip-over-ethernet-socket>, destination :: <ipv4-address>, data);
  if (destination = broadcast-address(socket.socket-owner.@ip-address))
    sendto(socket.lower-socket, $broadcast-ethernet-address, data)
  else
    arp-resolve(socket.socket-owner.@arp-handler, destination,
                method(x) sendto(socket.lower-socket, x, data) end)
  end
end;



