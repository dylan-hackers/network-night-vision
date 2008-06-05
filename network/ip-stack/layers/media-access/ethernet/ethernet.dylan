module: ethernet

define layer ethernet (<layer>)
  inherited property administrative-state = #"up";
  property mac-address :: <mac-address> = mac-address("08:00:05:00:00:03"); 
end;

define method read-as (type :: subclass(<leaf-frame>), value :: <string>) => (res)
  read-frame(type, value)
end;

define class <ethernet-socket> (<socket>)
  constant slot lower-socket :: <socket>, required-init-keyword: lower-socket:;
  constant slot decapsulator :: <decapsulator> = make(<decapsulator>);
  constant slot completer :: <completer>, required-init-keyword: completer:;
end;

define method create-socket (layer :: <ethernet-layer>, #rest rest, #key filter-string, tap?, #all-keys)
 => (res :: <socket>)
  unless(layer.@running-state == #"up")
    error("Layer down");
  end;
  let filter = format-to-string("(ethernet.destination-address = %s) | (ethernet.destination-address = ff:ff:ff:ff:ff:ff)", as(<string>, layer.@mac-address));
  if (filter-string)
    filter := format-to-string("(%s) & (%s)", filter, filter-string);
  end;
  if (tap?)
    create-socket(layer.lower-layers[0], tap?: #t, filter-string: filter);
  else
    let socket = create-socket(layer.lower-layers[0], filter-string: filter);
    let completer = make(<completer>, template-frame: ethernet-frame(source-address: layer.@mac-address));
    let res = make(<ethernet-socket>,
		   owner: layer,
		   lower-socket: socket,
		   completer: completer);
    connect(socket.socket-output, res.decapsulator);
    connect(completer, socket.socket-input);
    res
  end;
end;

define method socket-input (socket :: <ethernet-socket>) => (res :: <input>)
  socket.completer.the-input
end;
define method socket-output (socket :: <ethernet-socket>) => (res :: <output>)
  socket.decapsulator.the-output;
end;

define method close-socket (socket :: <ethernet-socket>)
  next-method();
  close-socket(socket.lower-socket);
end;

define method sendto (socket :: <ethernet-socket>, destination :: <mac-address>, data);
  let frame = ethernet-frame(destination-address: destination, payload: data);
  send(socket, frame);
end;

define method send (socket :: <ethernet-socket>, data)
  push-data-aux(socket.completer.the-input, socket.completer, data)
end;

define method check-upper-layer? (lower :: <ethernet-layer>, upper :: <layer>) => (allowed? :: <boolean>);
  #t;
end;

define method check-lower-layer? (upper :: <ethernet-layer>, lower :: <layer>) => (allowed? :: <boolean>);
  upper.@running-state == #"down" &
    check-socket-arguments?(lower, type: <ethernet-frame>);
end;

define method check-socket-arguments? (lower :: <ethernet-layer>,
				       #rest rest, #key type, #all-keys)
 => (valid-arguments? :: <boolean>)
  //XXX: if (valid-type?)
  #t;
end;

define method register-lower-layer (upper :: <ethernet-layer>, lower :: <layer>)
  register-property-changed-event
    (lower, #"running-state",
     method(x)
	 if (x.property-changed-event-property.property-value == #"up")
	   upper.@running-state := #"up"
	 else
	   upper.@running-state := #"down"
	 end
     end, owner: upper)
end;

define method deregister-lower-layer (upper :: <ethernet-layer>, lower :: <layer>)
  do(close-socket, upper.sockets);
  upper.@running-state := #"down";
end;

