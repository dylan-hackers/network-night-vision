module: ip-over-ethernet
synopsis: 
author: 
copyright: 

define layer ip-over-ethernet (<ip-adapter-layer>)
  property arp-handler :: <layer>;
end;

define method check-upper-layer? (lower :: <ip-over-ethernet-layer>, upper :: <layer>) => (allowed? :: <boolean>);
  #t;
end;

define method check-lower-layer? (upper :: <ip-over-ethernet-layer>, lower :: <layer>) => (allowed? :: <boolean>);
  upper.@running-state == #"down" &
    check-socket-arguments?(lower, type: <ipv4-frame>);
end;

define method register-lower-layer (upper :: <ip-over-ethernet-layer>, lower :: <layer>)
  upper.@running-state := #"up";
end;

define method deregister-lower-layer (upper :: <ip-over-ethernet-layer>, lower :: <layer>)
  do(close-socket, upper.sockets);
  upper.@running-state := #"down";
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
  let res = make(<ip-over-ethernet-socket>, owner: layer, lower-socket: socket);
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



