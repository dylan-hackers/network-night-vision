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

define constant $object-table = make(<table>);

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

define method execute (c :: <list-command>, #key)
  let devices = find-all-devices();
  do(method (x)
       $object-table[as(<symbol>, x.device-name)] := x
     end, devices);
  map(device-name, devices)
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
    let ethernet-layer = build-ethernet-layer(interface, default-mac-address: mac);
    let ethernet-socket = create-raw-socket(ethernet-layer);
    let sum = make(<closure-node>, closure: curry(print-summary, *events-socket*));
    connect(ethernet-socket, sum);
    #("connected!")
  exception (c :: <condition>)
    struct(error: format-to-string("Cannot open interface %=: %=", interface, c));
  end
end;

define function execute-handler (#key command, arguments)
  let response = current-response();
  set-header(response, "Content-type", "application/json");
  let result = apply(execute, $command-table[as(<symbol>, command)], arguments);
  encode-json(response, result)
end;

let execute-resource = make(<function-resource>, function: execute-handler);
add-resource(server, "/execute/{command}/{arguments*}", execute-resource);

start-server(server);
