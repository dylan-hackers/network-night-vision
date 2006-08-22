Module:    flow
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define class <graph> (<object>)
  slot nodes :: <stretchy-vector> = make(<stretchy-vector>);
end;

define class <node> (<object>)
  slot graph :: <graph> = *global-flow*, init-keyword: graph:;
end;

define open generic toplevel (node :: <node>);
define thread variable *global-flow* = make(<graph>);

define method initialize(node :: <node>, #rest rest, #key, #all-keys)
  next-method();
  add!(node.graph.nodes, node);
end;

define class <input> (<object>)
  slot node :: <node>, required-init-keyword: node:;
  slot connected-output :: false-or(<output>) = #f;
end;

define open class <push-input> (<input>)
end;

define open class <pull-input> (<input>)
end;

define class <output> (<object>)
  slot node :: <node>, required-init-keyword: node:;
  slot connected-input :: false-or(<input>) = #f;
end;

define open class <push-output> (<output>)
end;

define open class <pull-output> (<output>)
end;

define generic process (node :: <node>) => ();

define generic get-inputs (node :: <node>) => (inputs);

define generic get-outputs (node :: <node>) => (outputs);

define open generic connect (output, input);

define open generic disconnect (output, input);

define method connect (output :: <push-output>, input :: <push-input>)
  output.connected-input := input;
  input.connected-output := output;
end;

define method disconnect (output :: <push-output>, input :: <push-input>)
  output.connected-input := #f;
  input.connected-output := #f;
end;

define method connect (output :: <pull-output>, input :: <pull-input>)
  output.connected-input := input;
  input.connected-output := output;
end;

define method disconnect (output :: <pull-output>, input :: <pull-input>)
  output.connected-input := #f;
  input.connected-output := #f;
end;

define open generic pull-data-aux (output :: <pull-output>, node :: <node>);

define method pull-data (input :: <pull-input>) => (data)
  input.connected-output 
    & pull-data-aux(input.connected-output, input.connected-output.node)
end;

define open generic push-data-aux (input :: <push-input>, node :: <node>, data);

define method push-data (output :: <push-output>, data)
  output.connected-input 
    & push-data-aux(output.connected-input, output.connected-input.node, data)
end;

define abstract class <single-input-node> (<node>)
  slot the-input :: <input>, init-keyword: input:;
end;

define open abstract class <single-push-input-node> (<single-input-node>)
end;

define method initialize(node :: <single-push-input-node>, #rest rest, #key, #all-keys)
  next-method();
  node.the-input := make(<push-input>, node: node)
end;

define method get-inputs (node :: <single-input-node>) => (inputs)
  list(node.the-input)
end;

define open abstract class <single-pull-input-node> (<single-input-node>)
end;

define method initialize(node :: <single-pull-input-node>, #rest rest, #key, #all-keys)
  next-method();
  node.the-input := make(<pull-input>, node: node)
end;

define open abstract class <single-output-node> (<node>)
  slot the-output :: <push-output>, init-keyword: output:;
end;

define open abstract class <single-push-output-node> (<single-output-node>)
end;

define method initialize(node :: <single-push-output-node>, #rest rest, #key, #all-keys)
  next-method();
  node.the-output := make(<push-output>, node: node)
end;

define method get-outputs (node :: <single-output-node>) => (outputs)
  list(node.the-output)
end;

define open abstract class <single-pull-output-node> (<single-output-node>)
end;

define method initialize(node :: <single-pull-output-node>, #rest rest, #key, #all-keys)
  next-method();
  node.the-output := make(<pull-output>, node: node)
end;

define method connect (node :: <single-output-node>, input :: <input>)
  connect(node.the-output, input)
end;

define method disconnect (node :: <single-output-node>, input :: <input>)
  disconnect(node.the-output, input);
end;

define method connect (output :: <output>, node :: <single-input-node>)
  connect(output, node.the-input)
end;

define method disconnect (output :: <output>, node :: <single-input-node>)
  disconnect(output, node.the-input);
end;

define method connect (output :: <single-output-node>, input :: <single-input-node>)
  connect(output.the-output, input.the-input)
end;

define method disconnect (output :: <single-output-node>, input :: <single-input-node>)
  disconnect(output.the-output, input.the-input);
end;

define open abstract class <filter> (<single-push-input-node>, <single-push-output-node>)
end;

define class <queue> (<single-push-input-node>, <single-pull-output-node>)
  slot queue :: <deque> = make(<deque>);
  slot lock :: <lock> = make(<lock>);
end;

define method push-input-aux (input :: <push-input>, node :: <queue>, data)
  with-lock(node.lock)
    push-last(node.queue, data)
  end
end;

define method pull-output-aux (output :: <pull-output>, node :: <queue>) => (data)
  with-lock(node.lock)
    node.queue.size > 0 & node.queue.pop
  end
end;



