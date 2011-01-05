module: ip
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define layer ip (<layer>)
  inherited property administrative-state = #"up";
  inherited property running-state = #"up";
  constant slot routes = make(<stretchy-vector>);
  constant slot fan-in = make(<fan-in>);
  constant slot demultiplexer = make(<demultiplexer>);
end;

define method initialize-layer (layer :: <ip-layer>, #key, #all-keys) => () 
  let cls = make(<closure-node>,
                 closure: method(x)
                              let (socket, next-hop)
                                = find-forwarding-socket(layer, x.destination-address);
                              sendto(socket, next-hop, x);
                          end);
  connect(layer.fan-in, cls);
end;

define method check-upper-layer? (lower :: <ip-layer>, upper :: <layer>) => (allowed? :: <boolean>);
  #t;
end;

define method check-lower-layer? (upper :: <ip-layer>, lower :: <layer>) => (allowed? :: <boolean>);
  instance?(lower, <ip-adapter-layer>) & check-socket-arguments?(lower, type: <ipv4-frame>);
end;

define method register-lower-layer (upper :: <ip-layer>, lower :: <ip-adapter-layer>)
  register-property-changed-event(lower, #"running-state",
                                  rcurry(toggle-running-state, upper, lower),
                                  owner: upper)
end;

define function toggle-running-state (event :: <property-changed-event>,
                                      upper :: <ip-layer>, lower :: <ip-adapter-layer>)
  if (event.property-changed-event-property.property-value == #"up")
    let socket = create-socket(lower, type: <ipv4-frame>);
    let route = make(<connected-route>,
                     cidr: lower.@ip-address,
                     socket: socket);
    register-route(upper, route);
    connect(socket.socket-output, upper.fan-in);
  else
    if (event.property-changed-event-old-value == #"up")
      delete-route(upper, lower.@ip-address);
      close-socket(lower.sockets[0]);
    end
  end
end;

define method deregister-lower-layer (upper :: <ip-layer>, lower :: <ip-adapter-layer>)
  if (lower.@running-state == #"up")
    delete-route(upper, lower.@ip-address);
    close-socket(lower.sockets[0]);
  end;
end;

//XXX: probably should use radix trees

define abstract class <route> (<object>)
  constant slot cidr :: <cidr>, required-init-keyword: cidr:;
end;

define class <next-hop-route> (<route>)
  constant slot next-hop :: <ipv4-address>, required-init-keyword: next-hop:;
end;

define method print-object (object :: <next-hop-route>, stream :: <stream>) => ()
  format(stream, "%= -> %s", object.cidr, object.next-hop);
end;

define class <connected-route> (<route>)
  constant slot socket :: <socket>, required-init-keyword: socket:;
end;

define method print-object (object :: <connected-route>, stream :: <stream>) => ()
  format(stream, "%= -> %=", object.cidr, object.socket.socket-owner);
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

define function add-next-hop-route (ip-layer :: <ip-layer>, cidr :: <cidr>, next-hop :: <ipv4-address>)
  register-route(ip-layer, make(<next-hop-route>,
                                next-hop: next-hop,
                                cidr: cidr));
end;

define function delete-route (ip-layer :: <ip-layer>, mycidr :: <cidr>)
  let route = choose(method(x) x.cidr = mycidr end, ip-layer.routes);
  do(curry(remove!, ip-layer.routes), route);
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

define method find-forwarding-socket (ip-layer :: <ip-layer>, destination-address :: <ipv4-address>)
 => (res :: <socket>, next-hop :: <ipv4-address>);
  let direct-route = find-route(ip-layer.routes, destination-address);
  unless (direct-route)
    error("No route to host")
  end;
  if (instance?(direct-route, <connected-route>))
    values(direct-route.socket, destination-address);
  else
    let route = find-route(ip-layer.routes, direct-route.next-hop);
    if (instance?(route, <connected-route>))
      values(route.socket, direct-route.next-hop)
    else
      error("No direct route to next-hop");
    end;
  end;
end;
