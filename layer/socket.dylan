module: socket

define open abstract class <socket> (<object>)
  constant slot socket-owner, required-init-keyword: owner:;
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
define method close-socket (socket :: <socket>) end;

define class <flow-node-socket> (<socket>)
  constant slot flow-node /* :: <node> */, required-init-keyword: flow-node:;
end;

define method send (node :: <flow-node-socket>, data)
  push-data(node.flow-node.the-output, data)
end;
