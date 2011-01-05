Module:    dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

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

  export get-inputs, get-outputs, output-label;

  export
    <single-push-input-node>, <single-pull-input-node>,
    <single-push-output-node>, <single-pull-output-node>,
    <filter>, <closure-node>;

  export <queue>, the-input, the-output;

end module flow;
