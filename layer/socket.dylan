module: socket

define open abstract class <socket> (<object>)
  constant slot socket-owner, required-init-keyword: owner:;
end;

define method initialize (socket :: <socket>, #key, #all-keys)
  socket.socket-owner.sockets := add!(socket.socket-owner.sockets, socket);
end;
define open generic check-socket-arguments? (layer :: <layer>, #key, #all-keys)
 => (valid-socket-arguments? :: <boolean>);

define method check-socket-arguments? (layer :: <layer>, #rest rest, #key, #all-keys)
 => (valid-socket-arguments? :: <boolean>);
  #f;
end;  
define open generic create-socket (layer :: <layer>, #key, #all-keys) => (socket :: <socket>);

define open generic send (socket :: <socket>, data);

define method send (node :: <socket>, data)
  if (node.socket-input.connected-output)
    push-data(node.socket-input.connected-output, data)
  end;
end;

define open generic sendto (socket :: <socket>, destination, data);

define open generic close-socket (socket :: <socket>);
define method close-socket (socket :: <socket>)
  socket.socket-owner.sockets := remove!(socket.socket-owner.sockets, socket);
  disconnect(socket.socket-output, socket.socket-output.connected-input);
  disconnect(socket.socket-input.connected-output, socket.socket-input);
end;

define open generic socket-input (socket :: <socket>) => (res /* :: <input> */);

define open generic socket-output (socket :: <socket>) => (res /* :: <output> */);

define class <flow-node-socket> (<socket>)
  constant slot flow-node /* :: <node> */, required-init-keyword: flow-node:;
end;

define method socket-input (flow-node-socket :: <flow-node-socket>) => (res :: <input>)
  flow-node-socket.flow-node.the-input;
end;
define method socket-output (flow-node-socket :: <flow-node-socket>) => (res :: <output>)
  flow-node-socket.flow-node.the-output;
end;

define class <input-output-socket> (<socket>)
  constant slot socket-input /* :: <input> */, required-init-keyword: input:;
  constant slot socket-output /* :: <output> */, required-init-keyword: output:;
end;

define class <tapping-socket> (<socket>)
  slot fan-in = make(<fan-in>);
  slot socket-fan-out;
  slot frame-filter :: <frame-filter>;
  slot demux-output :: <output>;
end;

define method close-socket (socket :: <tapping-socket>)
  socket.socket-owner.sockets := remove!(socket.socket-owner.sockets, socket);
  disconnect(socket.socket-output, socket.socket-output.connected-input);
  disconnect(socket.socket-fan-out, socket.frame-filter.the-input);
  disconnect(socket.demux-output, socket.fan-in);
end;

define method socket-input (socket :: <tapping-socket>) => (res /* :: <input> */);
  error("Tapping sockets are read-only");
end;

define method socket-output (socket :: <tapping-socket>) => (res /* :: <output> */);
  socket.fan-in.the-output;
end;

define function create-tapping-socket
    (layer :: <layer>,
     fan-out :: <fan-out>,
     demultiplexer :: <demultiplexer>,
     #key filter-string)
 => (res :: <tapping-socket>)
  let socket = make(<tapping-socket>, owner: layer);
  //XXX: frame-filter should be the frame-type we are interested in
  socket.frame-filter := make(<frame-filter>, frame-filter: "");
  socket.socket-fan-out := fan-out;
  connect(fan-out, socket.frame-filter);
  connect(socket.frame-filter, socket.fan-in);
  socket.demux-output := create-output-for-filter(demultiplexer, filter-string);
  connect(socket.demux-output, socket.fan-in);
  socket;
end;

