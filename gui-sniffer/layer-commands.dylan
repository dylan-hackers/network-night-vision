module: layer-commands

begin
  start-layer();
end;

define class <show-config-command> (<basic-command>)
end;

define command-line show-config => <show-config-command>
  (summary: "Shows config",
   documentation: "Shows config of all layers")
end;

define method do-execute-command (context :: <nnv-context>, command :: <show-config-command>)
  let out = context.context-server.server-output-stream;
  do(curry(print-config, out), find-all-layers());
end;


define class <show-layers-command> (<basic-command>)
end;

define command-line show-layers => <show-layers-command>
  (summary: "Shows all layers",
   documentation: "Shows all registered layers")
end;

define method do-execute-command (context :: <nnv-context>, command :: <show-layers-command>)
  let out = context.context-server.server-output-stream;
  do(curry(print-layer, out), find-all-layers());
end;


define method parse-next-argument
    (context :: <nnv-context>, type == <layer>,
     text :: <string>,
     #key start :: <integer> = 0, end: stop = #f)
 => (value :: <layer>, next-index :: <integer>)
   block (return)
     let (name, next-index)
       = parse-next-word(text, start: start, end: stop);
     if (find-layer(name))
       values(find-layer(name), next-index)
     else
       parse-error("Missing argument.")
     end
   exception (e :: <condition>)
     parse-error("Layer not found")
   end;
end;

define class <show-layer-command> (<basic-command>)
  constant slot %layer :: <layer>, required-init-keyword: layer:;
end;

define command-line show-layer => <show-layer-command>
  (summary: "Show properties of a layer",
   documentation:  "Shows properties of a layer")
  argument layer :: <layer> = "The layer which properties should be displayed"
end;

define method do-execute-command (context :: <nnv-context>, command :: <show-layer-command>)
  let out = context.context-server.server-output-stream;
  do(curry(print-property, out), get-properties(command.%layer));
end;

define class <set-l-property-command> (<basic-command>)
  constant slot %layer :: <layer>, required-init-keyword: layer:;
  constant slot %property-name :: <symbol>, required-init-keyword: property-name:;
  constant slot %property-value :: <string>, required-init-keyword: property-value:;
end;

define command-line !set => <set-l-property-command>
  (summary: "Set layer property",
   documentation: "Sets a given property to the given value in the given layer")
  argument layer :: <layer> = "Layer to work on";
  argument property-name :: <symbol> = "Property name";
  argument property-value :: <string> = "Property value";
end;

define method do-execute-command (context :: <nnv-context>, command :: <set-l-property-command>)
  let property = get-property(command.%layer, command.%property-name);
  read-into-property(property, chop(command.%property-value));
end;

define command-group layer
    (summary: "Layer commands",
     documentation: "The set of commands for managing the layers.")
  command show-config;
  command show-layers;
  command show-layer;
  command !set;
end command-group;

