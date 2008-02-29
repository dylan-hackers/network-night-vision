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
define open generic close-socket (socket :: <socket>);
define method close-socket (socket :: <socket>)
  socket.socket-owner.sockets := remove!(socket.socket-owner.sockets, socket);
end;
define class <flow-node-socket> (<socket>)
  constant slot flow-node /* :: <node> */, required-init-keyword: flow-node:;
end;

define method send (node :: <flow-node-socket>, data)
  push-data(node.flow-node.the-input, data)
end;

define class <input-output-socket> (<socket>)
  constant slot socket-input, required-init-keyword: input:;
  constant slot socket-output, required-init-keyword: output:;
end;

define method send (node :: <input-output-socket>, data)
  if (node.socket-input.connected-output)
    push-data(node.socket-input.connected-output, data)
  end;
end;

define method close-socket (socket :: <input-output-socket>)
  next-method();
  disconnect(socket.socket-output, socket.socket-output.connected-input);
  disconnect(socket.socket-input.connected-output, socket.socket-input);
end;

