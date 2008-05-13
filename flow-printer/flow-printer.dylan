module: flow-printer
synopsis: 
author: 
copyright: 

define function print-flow (stream :: <stream>, graph :: <graph>) => ()
  let graphviz = make(graphviz-<graph>);
  for (n in graph.nodes)
    let nod = graphviz-find-node!(graphviz, format-to-string("%=", n));

    //format(stream, "processing %=\n", n);
    for (out in n.get-outputs)
      //format(stream, "  looking at output %=\n", out);
      if (out.connected-input)
	let targ = format-to-string("%=", out.connected-input.node);
	//format(stream, "  adding output %s\n", targ);
	graphviz-create-edge(graphviz, nod,
			     graphviz-find-node!(graphviz, targ),
			     label: output-label(out));
      end;
    end;
  end;
  let graph-file = graphviz-generate-graph(graphviz,
					   graphviz.graphviz-nodes.first);
  format(stream, "%s\n", graph-file);
end;