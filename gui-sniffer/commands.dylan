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
     parse-error("Not a valid target.")
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
  let icmp = icmp-frame(code: 0, icmp-type: 8,
                        payload: read-frame(<raw-frame>, "123412341234123412341234123412341234123412341234"));
  send(context.nnv-context.ip-layer, target, icmp);
  format(stream, "Ping sent!\n");
end;

define command-group nnv
    (summary: "Network Night Vision commands",
     documentation: "The set of commands provided by Network Night Vision.")
  command ping;
  group basic;
  group property;
end command-group;

define method context-command-group
    (context :: <nnv-context>) => (group :: <command-group>)
  $nnv-command-group
end method context-command-group;

define method context-command-prefix
    (context :: <nnv-context>) => (prefix :: <character>)
  '>'
end method context-command-prefix;




