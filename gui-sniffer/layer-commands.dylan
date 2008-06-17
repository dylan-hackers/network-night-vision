module: layer-commands

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

define class <save-config-command> (<basic-command>)
  constant slot %filename :: <string>, required-init-keyword: filename:;
end;

define command-line save-config => <save-config-command>
  (summary: "Saves config",
   documentation: "Saves config of all layers")
  argument filename :: <string> = "Filename where to save the config"
end;

define method do-execute-command (context :: <nnv-context>, command :: <save-config-command>)
  let filename = if (command.%filename = "")
                   concatenate(environment-variable("HOME"), "/.nnv-config")
                 else
                   copy-sequence(command.%filename, end: command.%filename.size - 1);
                 end;
  with-open-file (file = filename, direction: #"output", if-exists?: #"overwrite")
    do(curry(print-config, file), find-all-layers());
  end;
end;

define class <load-config-command> (<basic-command>)
  constant slot %filename :: <string>, required-init-keyword: filename:;
end;

define command-line load-config => <load-config-command>
  (summary: "Load config",
   documentation: "Loads configuration from a given file")
  argument filename :: <string> = "Filename where to load the config"
end;

define method do-execute-command (context :: <nnv-context>, command :: <load-config-command>)
  let filename = if (command.%filename = "")
                   concatenate(environment-variable("HOME"), "/.nnv-config")
                 else
                   copy-sequence(command.%filename, end: command.%filename.size - 1);
                 end;
  with-open-file (file = filename, direction: #"input")
    read-config(file);
  end;
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
  print-layer(context.context-server.server-output-stream, command.%layer);
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

define class <connect-command> (<basic-command>)
  constant slot %lower :: <layer>, required-init-keyword: lower:;
  constant slot %upper :: <layer>, required-init-keyword: upper:;
end;

define command-line connect => <connect-command>
  (summary: "Connect lower to upper layer",
   documentation: "Tries to plug the upper layer into the lower layer.")
  argument lower :: <layer> = "Name of lower layer to connect.";
  argument upper :: <layer> = "Name of upper layer to connect.";
end;

define method do-execute-command (context :: <nnv-context>, command :: <connect-command>)
  connect-layer(command.%lower, command.%upper);
end;
define class <disconnect-command> (<basic-command>)
  constant slot %lower :: <layer>, required-init-keyword: lower:;
  constant slot %upper :: <layer>, required-init-keyword: upper:;
end;

define command-line disconnect => <disconnect-command>
  (summary: "Disconnect lower and upper layer",
   documentation: "Unplugs the upper layer out of the lower layer.")
  argument lower :: <layer> = "Name of lower layer to disconnect.";
  argument upper :: <layer> = "Name of upper layer to disconnect.";
end;

define method do-execute-command (context :: <nnv-context>, command :: <disconnect-command>)
  disconnect-layer(command.%lower, command.%upper);
end;

define class <layer-type> (<object>)
  constant slot ltype :: subclass(<layer>), required-init-keyword: type:;
end;

define method parse-next-argument
    (context :: <nnv-context>, type == <layer-type>,
     text :: <string>,
     #key start :: <integer> = 0, end: stop = #f)
 => (value :: <layer-type>, next-index :: <integer>)
   block (return)
     let (name, next-index)
       = parse-next-word(text, start: start, end: stop);
     if (find-layer-type(name))
       values(make(<layer-type>, type: find-layer-type(name)),
              next-index)
     else
       parse-error("Missing argument.")
     end
   exception (e :: <condition>)
     parse-error("Layer-type not found")
   end;
end;

define class <create-command> (<basic-command>)
  constant slot %layer-type :: <layer-type>, required-init-keyword: layer-type:;
  constant slot %layer-name :: <string>, required-init-keyword: layer-name:;
end;

define command-line create => <create-command>
  (summary: "Creates a new layer",
   documentation: "Instantiates a new layer of given type.")
  argument layer-type :: <layer-type> = "Type of layer to create.";
  argument layer-name :: <string> = "Name of layer to create.";
end;

define method do-execute-command (context :: <nnv-context>, command :: <create-command>)
  let layer = make(command.%layer-type.ltype, name: as(<symbol>, chop(command.%layer-name)));
  let out = context.context-server.server-output-stream;
  format(out, "Layer %s of type %s created\n", layer.layer-name, layer.default-name);
end;

define class <up-command> (<basic-command>)
  constant slot %layer :: <layer>, required-init-keyword: layer:;
end;

define command-line up => <up-command>
  (summary: "Set administrative state of layer to 'up'.",
   documentation: "Set administrative state of layer to 'up'.")
  argument layer :: <layer> = "Layer to bring up.";
end;

define method do-execute-command (context :: <nnv-context>, command :: <up-command>)
  let layer = command.%layer;
  set-property-value(layer, #"administrative-state", #"up");
end;

define class <down-command> (<basic-command>)
  constant slot %layer :: <layer>, required-init-keyword: layer:;
end;

define command-line down => <down-command>
  (summary: "Set administrative state of layer to 'down'.",
   documentation: "Set administrative state of layer to 'down'.")
  argument layer :: <layer> = "Layer to bring down.";
end;

define method do-execute-command (context :: <nnv-context>, command :: <down-command>)
  let layer = command.%layer;
  set-property-value(layer, #"administrative-state", #"down");
end;

define class <resolve-arp-command> (<basic-command>)
  constant slot %layer :: <layer>, required-init-keyword: layer:;
  constant slot %ip :: <ipv4-address>, required-init-keyword: ip:;
end;

define command-line resolve-arp => <resolve-arp-command>
  (summary: "Resolve ARP.",
   documentation: "Resolve IP address.")
  argument layer :: <layer> = "Layer";
  argument ip :: <ipv4-address> = "IP";
end;

define method do-execute-command (context :: <nnv-context>,
				  command :: <resolve-arp-command>)
  let layer = command.%layer;
  let out = context.context-server.server-output-stream;
  arp-resolve(layer, command.%ip,
	      method(x)
		  format(out,
			 "ARP: IP %= is at %=\n",
			 command.%ip, x);
	      end);
end;

define class <show-arp-table-command> (<basic-command>)
  constant slot %layer :: <layer>, required-init-keyword: layer:;
end;

define command-line show-arp-table => <show-arp-table-command>
  (summary: "Shows ARP table.",
   documentation: "Shows current ARP table")
  argument layer :: <layer> = "ARP handler to query.";
end;

define method do-execute-command (context :: <nnv-context>, command :: <show-arp-table-command>)
  print-arp-table(context.context-server.server-output-stream,
                  command.%layer);
end;

define class <show-forwarding-table-command> (<basic-command>)
  constant slot %layer :: <layer>, required-init-keyword: layer:;
end;

define command-line show-forwarding-table => <show-forwarding-table-command>
  (summary: "Shows forwarding table.",
   documentation: "Prints current forwarding table")
  argument layer :: <layer> = "IP Layer to operate on";
end;

define method do-execute-command (context :: <nnv-context>, command :: <show-forwarding-table-command>)
  print-forwarding-table(context.context-server.server-output-stream,
                         command.%layer);
end;

define class <add-route-command> (<basic-command>)
  constant slot %layer :: <layer>, required-init-keyword: layer:;
  constant slot %gateway :: <ipv4-address>, required-init-keyword: gateway:;
  constant slot %network :: <cidr>, required-init-keyword: network:;
end;

define command-line add-route => <add-route-command>
  (summary: "Adds route.",
   documentation: "Adds route to forwarding table")
  argument layer :: <layer> = "IP Layer to operate on";
  argument network :: <cidr> = "Network";
  argument gateway :: <ipv4-address> = "Gateway";
end;

define method do-execute-command (context :: <nnv-context>, command :: <add-route-command>)
  add-next-hop-route(command.%layer, command.%network, command.%gateway);
end;

define class <delete-route-command> (<basic-command>)
  constant slot %layer :: <layer>, required-init-keyword: layer:;
  constant slot %network :: <cidr>, required-init-keyword: network:;
end;

define command-line delete-route => <delete-route-command>
  (summary: "Delete route.",
   documentation: "Deletes route from forwarding table")
  argument layer :: <layer> = "IP Layer to operate on";
  argument network :: <cidr> = "Network";
end;

define method do-execute-command (context :: <nnv-context>, command :: <delete-route-command>)
  delete-route(command.%layer, command.%network);
end;

/*
define class <advertise-arp-command> (<basic-command>)
  constant slot %layer :: <layer>, required-init-keyword: layer:;
  constant slot %ip :: <ipv4-address>, required-init-keyword: ip:;
  constant slot %mac :: <mac-address>, required-init-keyword: mac:;
end;

define command-line advertise-arp => <advertise-arp-command>
  (summary: "Advertise given ARP entry.",
   documentation: "Advertise MAC address on the specific layer with the specified IP address.")
  argument layer :: <layer> = "Layer";
  argument ip :: <ipv4-address> = "IP";
  argument mac :: <mac-address> = "MAC";
end;

define method do-execute-command (context :: <nnv-context>, command :: <down-command>)
  let layer = command.%layer;
  layer.
end;
*/
 
define command-group layer
    (summary: "Layer commands",
     documentation: "The set of commands for managing the layers.")
  command show-config;
  command save-config;
  command load-config;
  command show-layers;
  command show-layer;
  command !set;
  command connect;
  command disconnect;
  command create;
  command up;
  command down;
  command resolve-arp;
  command show-arp-table;
  command show-forwarding-table;
  command add-route;
  command delete-route;
end command-group;

