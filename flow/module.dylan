Module:    dylan-user
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define module flow
  use common-dylan;
  use threads;

  export 
    <graph>, nodes, *global-flow*,
    <node>, graph,
    <input>, node, connected-output,
    <push-input>, <pull-input>,
    <output>, connected-input,
    <push-output>, <pull-output>,
    push-data, pull-data,
    push-data-aux, pull-data-aux,
    connect, disconnect, toplevel;

  export 
    <single-push-input-node>, <single-pull-input-node>,
    <single-push-output-node>, <single-pull-output-node>,
    <filter>, <closure-node>;

  export <queue>, the-input, the-output;

end module flow;
