module: gui-sniffer

define method parse-next-argument
    (context :: <nnv-context>, type == <ipv4-address>,
     text :: <string>,
     #key start :: <integer> = 0, end: stop = #f)
 => (value :: <ipv4-address>, next-index :: <integer>)
   block (return)
     let (name, next-index)
       = parse-next-word(text, start: start, end: stop);
     if (name)
       values(ipv4-address(name), next-index)
     else
       parse-error("Missing argument.")
     end
   exception (e :: <condition>)
     parse-error("Not a valid IP address.")
   end;
end;

define method parse-next-argument
    (context :: <nnv-context>, type == <cidr>,
     text :: <string>,
     #key start :: <integer> = 0, end: stop = #f)
 => (value :: <cidr>, next-index :: <integer>)
   block (return)
     let (name, next-index)
       = parse-next-word(text, start: start, end: stop);
     if (name)
       values(as(<cidr>, name), next-index)
     else
       parse-error("Missing argument.")
     end
   exception (e :: <condition>)
     parse-error("Not a valid CIDR.")
   end;
end;

define method parse-next-argument
    (context :: <nnv-context>, type == <filter-expression>,
     text :: <string>,
     #key start :: <integer> = 0, end: stop = #f)
 => (value :: <filter-expression>, next-index :: <integer>)
  block (return)
    let (filter-string, next-index)
      = parse-next-word(text, start: start, end: stop, separators: #['\n']);
     values(parse-filter(filter-string), next-index)
  exception (e :: <condition>)
    parse-error("Not a valid filter expression.")
  end;
end;

define class <ping-command> (<basic-command>)
  constant slot %target :: <ipv4-address>, required-init-keyword: target:;
end;

define command-line ping => <ping-command>
    (summary: "Ping host.",
     documentation: "Sends an ICMP Echo Request to the specified target address.")
  argument target :: <ipv4-address> = "target host address";
end;

define method do-execute-command (context :: <nnv-context>, command :: <ping-command>)
  let target = command.%target;
  let stream = context.context-server.server-output-stream;
  let socket = create-filter-socket(context.nnv-context.ip-layer,
                                    list(protocol: 1, source-address: target),
                                    #());
  let timer = make(<timer>,
                   in: 10,
                   event: method()
                            format(stream, "Timeout waiting for response from %s\n", target);
                            close-socket(socket);
                          end);
  let response-handler = make(<closure-node>, 
                              closure: method(packet :: <icmp-frame>)
                                         format(stream, "Host %s is alive\n", target);
                                         cancel(timer);
                                         close-socket(socket);
                                       end);
  connect(socket, response-handler);
  let icmp = icmp-echo-request(icmp-data: read-frame(<raw-frame>, "123412341234123412341234123412341234123412341234"));
  send(context.nnv-context.ip-layer, target, icmp);
  format(stream, "Ping sent!\n");
end;

define class <dhcp-client-command> (<basic-command>)
end;

define command-line dhcp-client => <dhcp-client-command>
    (summary: "Aquire IP address via DHCP.",
     documentation:  "Initiates a DHCP client session, and configures IP stack with the acquired IP address.")
end;

define method do-execute-command (context :: <nnv-context>, command :: <dhcp-client-command>)
  let socket = create-socket(context.nnv-context.udp-layer, 67, client-port: 68);
  local method set-ip (frame :: <dhcp-message>)
          let ip = frame.your-ip-address;
          let subnet-mask = netmask-from-byte-vector(data(find-option(frame, <dhcp-subnet-mask>).subnet-mask));
          let router = find-option(frame, <dhcp-router-option>).addresses[0];
          set-ip-address(context.nnv-context.ip-over-ethernet-adapter, ip, subnet-mask);
          let default-cidr = as(<cidr>, "0.0.0.0/0");
          delete-route(context.nnv-context.ip-layer, default-cidr);
          add-next-hop-route(context.nnv-context.ip-layer, router, default-cidr);
          format(context.context-server.server-output-stream, "IP address configured from DHCP to %s\n", ip);
        end;
  let dhcp = make(<dhcp-client>, send-socket: socket, response-callback: set-ip);
  connect(socket.decapsulator, dhcp);
  process-event(dhcp, #"send-discover");
end;

define class <pppoe-client-command> (<basic-command>)
end;

define command-line pppoe-client => <pppoe-client-command>
    (summary: "Aquire PPPoE session.",
     documentation:  "Initiates a PPPoE client session, and aborts.")
end;

define method do-execute-command (context :: <nnv-context>, command :: <pppoe-client-command>)
  let socket = create-socket(context.nnv-context.ethernet-layer, #x8863);
  let pppoe = make(<pppoe-client>, send-socket: socket);
  connect(socket.decapsulator, pppoe);
  process-event(pppoe, #"padi-sent");
end;

define class <set-ip-address-command> (<basic-command>)
  constant slot %address :: <cidr>, required-init-keyword: address:;
end;

define command-line set-ip-address => <set-ip-address-command>
    (summary: "Set IP address.",
     documentation: "Sets the IP address of the current interface to the specified IP address")
   argument address :: <cidr> = "IP address and netmask in CIDR notation"
end;

define method do-execute-command (context :: <nnv-context>, command :: <set-ip-address-command>)
  let ip = context.nnv-context.ip-over-ethernet-adapter;
  set-ip-address(ip, command.%address.cidr-network-address, command.%address.cidr-netmask);
end;

define class <show-arp-table-command> (<basic-command>)
end;

define command-line show-arp-table => <show-arp-table-command>
  (summary: "Shows ARP table.",
   documentation: "Shows current ARP table")
end;

define method do-execute-command (context :: <nnv-context>, command :: <show-arp-table-command>)
  print-arp-table(context.context-server.server-output-stream,
                  context.nnv-context.ip-over-ethernet-adapter.arp-handler);
end;

define class <show-forwarding-table-command> (<basic-command>)
end;

define command-line show-forwarding-table => <show-forwarding-table-command>
  (summary: "Shows forwarding table.",
   documentation: "Prints current forwarding table")
end;

define method do-execute-command (context :: <nnv-context>, command :: <show-forwarding-table-command>)
  print-forwarding-table(context.context-server.server-output-stream,
                         context.nnv-context.ip-layer);
end;

define class <add-route-command> (<basic-command>)
  constant slot %gateway :: <ipv4-address>, required-init-keyword: gateway:;
  constant slot %network :: <cidr>, required-init-keyword: network:;
end;

define command-line add-route => <add-route-command>
  (summary: "Adds route.",
   documentation: "Adds route to forwarding table")
  argument network :: <cidr> = "Network";
  argument gateway :: <ipv4-address> = "Gateway";
end;

define method do-execute-command (context :: <nnv-context>, command :: <add-route-command>)
  add-next-hop-route(context.nnv-context.ip-layer, command.%gateway, command.%network);
end;

define class <delete-route-command> (<basic-command>)
  constant slot %network :: <cidr>, required-init-keyword: network:;
end;

define command-line delete-route => <delete-route-command>
  (summary: "Delete route.",
   documentation: "Deletes route from forwarding table")
  argument network :: <cidr> = "Network";
end;

define method do-execute-command (context :: <nnv-context>, command :: <delete-route-command>)
  delete-route(context.nnv-context.ip-layer, command.%network);
end;

define class <filter-command> (<basic-command>)
  constant slot %filter-expression :: <filter-expression>, required-init-keyword: expression:;
end;

define command-line filter => <filter-command>
  (summary: "Set filter for packet display",
   documentation:  "Sets the filter for display of packets in top pane")
  argument expression :: <filter-expression> = "The filter to apply"
end;

define method do-execute-command (context :: <nnv-context>, command :: <filter-command>)
  context.nnv-context.filter-field.gadget-value := format-to-string("%=", command.%filter-expression);
  apply-filter(context.nnv-context);
end;

define class <resolve-command> (<basic-command>)
  constant slot %host-name :: <string>, required-init-keyword: host-name:;
end;

define command-line resolve => <resolve-command>
  (summary: "Resolve host name using DNS",
   documentation:  "Resolve a host name to IP address using DNS.  Uses hard-coded resolver and query type.")
  argument host-name :: <string> = "The host to resolve"
end;

define method do-execute-command (context :: <nnv-context>, command :: <resolve-command>)
  let host-name = copy-sequence(command.%host-name, end: command.%host-name.size - 1);
  let stream = context.context-server.server-output-stream;
  let dns-query = dns-frame(questions: list(dns-question(domainname: as(<domain-name>, host-name))));
  let query = udp-frame(source-port: 53, destination-port: 53, payload: dns-query);
  send(context.nnv-context.ip-layer, ipv4-address("141.1.1.1"), query);
end;



define class <key-bindings-property> (<command-property>)
end;

define command-property key-bindings => <key-bindings-property> 
    (summary: "Summary of key bindings",
     documentation: "Shows a list of all editor key bindings")
end;

define method show-property
    (context :: <nnv-context>, property :: <key-bindings-property>)
 => ()
  let stream = context.context-server.server-output-stream;
  let docstrings = compute-key-binding-documentation(frame-command-set(context.nnv-context.nnv-shell-pane));
  do(curry(write-line, stream), docstrings);
end;

define command-group network
    (summary: "Networking commands",
     documentation: "The set of commands for managing the network.")
  command ping;
  command dhcp-client;
  command pppoe-client;
  command resolve;
  command set-ip-address;
  command add-route;
  command delete-route;
  command show-arp-table;
  command show-forwarding-table;
  command filter;
end command-group;

define class <tap-command> (<basic-command>)
  slot %layer :: new-<layer>, required-init-keyword: layer:
end;

define command-line tap => <tap-command>
  (summary: "Taps a layer",
   documentation: "Tap a layer")
  argument layer :: new-<layer> = "The layer to tap";
end;

define method do-execute-command (context :: <nnv-context>, command :: <tap-command>)
  let layer = command.%layer;
  if (context.nnv-context.tapping-socket)
    new-close-socket(context.nnv-context.tapping-socket);
  end;
  let tap = new-create-socket(layer, tap?: #t);
  context.nnv-context.tapping-socket := tap;
  connect(tap.new-socket-output, context.nnv-context);
end;

define class <flow-printer-command> (<basic-command>)
end;

define command-line flow-printer => <flow-printer-command>
  (summary: "Prints flow",
   documentation: "Prints the complete network flow")
end;

define method do-execute-command (context :: <nnv-context>, command :: <flow-printer-command>)
  print-flow(context.context-server.server-output-stream, *global-flow*);
end;

define command-group layer-gui
    (summary: "Layer command for the GUI",
     documentation: "The set of commands which connect the layer to the GUI")
  command tap;
  command flow-printer;
end;

define command-group nnv
    (summary: "Network Night Vision commands",
     documentation: "The set of commands provided by Network Night Vision.")
  group basic;
  group property;
  group network;
  group layer;
  group layer-gui;
  property key-bindings;
end command-group;

define method context-command-group
    (context :: <nnv-context>) => (group :: <command-group>)
  $nnv-command-group
end method context-command-group;

define method context-command-prefix
    (context :: <nnv-context>) => (prefix :: <character>)
  '>'
end method context-command-prefix;




