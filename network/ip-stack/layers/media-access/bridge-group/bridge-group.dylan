module: bridge-group

define layer repeater-group (<layer>)
  property administrative-state :: <symbol> = #"up";
end;

define class <output-node> (<single-push-output-node>)
end;
define method create-socket (repeater :: <repeater-group-layer>, #rest rest, #key, #all-keys)
 => (res :: <socket>)
  make(<flow-node-socket>,
       owner: repeater,
       flow-node: make(<output-node>));
end;

define method check-upper-layer? (lower :: <repeater-group-layer>, upper :: <layer>) => (allowed? :: <boolean>);
  #f;
end;

define method check-lower-layer? (upper :: <repeater-group-layer>, lower :: <layer>) => (allowed? :: <boolean>);
  check-socket-arguments?(lower, type: <ethernet-frame>);
end;

define method register-upper-layer (lower :: <repeater-group-layer>, upper :: <layer>)

end;

define method register-lower-layer (upper :: <repeater-group-layer>, lower :: <layer>)
  let ethernet-socket = create-socket(lower, type: <ethernet-frame>);
  let node = make(<closure-node>,
                  closure: method (x :: <ethernet-frame>)
                             if (upper.@administrative-state == #"up")
                               for (socket in upper.sockets)
                                 unless (socket == ethernet-socket)
                                   send(socket, x)
                                 end
                               end
                             end
                           end);
  connect(ethernet-socket.socket-output, node);
  connect(node.the-output, ethernet-socket.socket-input);
  upper.sockets := add!(upper.sockets, ethernet-socket);
end;

define method deregister-lower-layer (upper :: <repeater-group-layer>, lower :: <layer>)
  let layer-sockets = choose-by(curry(\=, lower),
                                map(socket-owner, upper.sockets),
                                upper.sockets);
  for (s in layer-sockets)
    close-socket(s);
    upper.sockets := remove!(upper.sockets, s);
  end;
end;

