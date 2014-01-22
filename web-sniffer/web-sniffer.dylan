module: web-sniffer

define function dbg (#rest args)
  apply(format-out, args);
  force-output(*standard-output*);
end;


let server = make(<http-server>,
                  listeners: list("127.0.0.1:8888"));

let static-resource = make(<directory-resource>,
                           directory: "/home/hannes/dylan/network-night-vision/web-sniffer/static",
                           allow-directory-listing?: #t);
add-resource(server, "/", static-resource);


define variable *events-socket* :: false-or(<stream>) = #f;

define function stream-function (#rest args)
  let req = current-request();
  let stream :: <stream> = req.request-socket;
  let response-line = format-to-string("%s %d %s",
                                       "HTTP/1.1",
                                       200,
                                       "OK");
  format(stream, "%s\r\n", response-line);
  format(stream, "Content-Type: text/event-stream\r\n\r\n");
  format(stream, "Cache-Control: no-cache\r\n\r\n");
  format(stream, "\r\n\r\n");

  dbg("events socket set to %=\n", stream);
  *events-socket* := stream;
  while (#t)
//different event types in JS!
//source.addEventListener('add', addHandler, false);
//source.addEventListener('remove', removeHandler, false);
//    format(stream, "data: %s\r\n\r\n", as-iso8601-string(current-date()));
//    force-output(stream);
    sleep(50);
  end;
end;

let stream-resource = make(<function-resource>,
                           function: stream-function);
add-resource(server, "/events", stream-resource);


define class <struct> (<object>)
  constant slot value :: <collection>, required-init-keyword: value:;
end;

define method print-object (s :: <struct>, stream :: <stream>) => ()
  encode-json(stream, s);
end;

define function struct (#rest args) => (struct :: <struct>)
  make(<struct>, value: args)
end;

define method encode-json (stream :: <stream>, object :: <struct>)
  write(stream, "{");
  for (key from 0 below object.value.size by 2,
       val from 1 by 2)
    if (key > 0)
      write(stream, ", ");
    end if;
    encode-json(stream, as(<string>, object.value[key]));
    write(stream, ":");
    encode-json(stream, object.value[val]);
  end for;
  write(stream, "}");
end;

define function help (#key partial)
  let response = current-response();
  set-header(response, "Content-type", "application/json");
  let res = make(<stretchy-vector>);
  for (x in $command-table)
    add!(res, struct(#"name", x.command-name,
                     #"description", x.command-description,
                     #"signature", x.command-signature));
  end;
  encode-json(response,res);
end;

let help-resource = make(<function-resource>, function: help);
add-resource(server, "/help/{partial}", help-resource);


define constant $command-table = make(<table>);

define constant $interface-table = make(<table>);

define abstract class <command> (<object>)
  constant slot command-name :: <symbol>, required-init-keyword: name:;
  constant slot command-description :: <string>, required-init-keyword: description:;
  constant slot command-signature :: <string> = "", init-keyword: signature:;
end;

define generic execute (c :: <command>, #rest args, #key, #all-keys);

define method make (class :: subclass(<command>), #rest rest, #key, #all-keys) =>
  (res :: <command>)
  let res = next-method();
  $command-table[res.command-name] := res
end;

define class <list-command> (<command>)
end;
make(<list-command>, name: #"list", description: "Lists all available interfaces");
make(<list-command>, name: #"clear", description: "Clears the event output");

define method execute (c :: <list-command>, #key)
  let devices = map(compose(curry(struct, open:, #f, name:), device-name),
                    find-all-devices());
  let open-devices = map(curry(struct, open:, #t, name:),
                         key-sequence($interface-table));
  ((open-devices.size > 0) & open-devices) | devices
end;

define class <open-command> (<command>)
end;
make(<open-command>, name: #"open", description: "Opens a network interface", signature: "<interface>");


define method recursive-summary (frame :: <header-frame>) => (res :: <string>)
  concatenate(summary(frame), "/", recursive-summary(frame.payload));
end;

define method recursive-summary (frame :: <frame>) => (res :: <string>)
  summary(frame);
end;

define function print-summary (stream :: <stream>, frame :: <object>)
  write(stream, "data: ");
  quote-html(recursive-summary(frame), stream: stream);
  write(stream, "\r\n\r\n");
  force-output(stream);
end;

define method execute (c :: <open-command>, #rest args, #key)
  let interface = args[0];
  block ()
    let mac = mac-address("00:de:ad:be:ef:00");
    dbg("mac %=\n", mac);
    let int = make(<ethernet-interface>, name: interface, promiscuous?: #t);
    dbg("int %=\n", int);
    assert(int.pcap-t);
    $interface-table[as(<symbol>, interface)] := int;
    dbg("interface-table.size %=\n", $interface-table.size);
    let ethernet-layer = make(<ethernet-layer>,
                              ethernet-interface: int,
                              default-mac-address: mac);
    dbg("eth %=\n", ethernet-layer);
    make(<thread>, function: curry(toplevel, int));
    let ethernet-socket = create-raw-socket(ethernet-layer);
    dbg("eth-socket %=\n", ethernet-socket);
    let sum = make(<closure-node>,
                   closure: curry(print-summary, *events-socket*));
    dbg("sum %=\n", sum);
    connect(ethernet-socket, sum);
    dbg("connected!\n");
    #("connected!")
  exception (c :: <condition>)
    list(struct(error: quote-html(format-to-string("Cannot open interface %=: %=", interface, c))))
  end
end;


define class <close-command> (<command>)
end;
make(<close-command>, name: #"close", description: "Closes a network interface", signature: "<interface>");

define method execute (c :: <close-command>, #rest args, #key)
  let interface = as(<symbol>, args[0]);
  block ()
    let int = $interface-table[interface];
    remove-key!($interface-table, interface);
    int.running? := #f;
    #("shutdown!")
  exception (c :: <condition>)
    list(struct(error: quote-html(format-to-string("Cannot close interface %=: %=", interface, c))))
  end
end;

define function execute-handler (#key command, arguments)
  let response = current-response();
  set-header(response, "Content-type", "application/json");
  block ()
    let result = apply(execute, $command-table[as(<symbol>, command)], arguments);
    dbg("sending back %=\n", result);
    encode-json(response, result)
  exception (c :: <condition>)
    encode-json(response, list(struct(error:, quote-html(format-to-string("error while executing handler %=", c)))))
  end;
end;

let execute-resource = make(<function-resource>, function: execute-handler);
add-resource(server, "/execute/{command}/{arguments*}", execute-resource);

start-server(server);
