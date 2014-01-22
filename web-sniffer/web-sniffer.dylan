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

let stream-resource = make(<sse-resource>);
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
  encode-json(response, res);
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

define constant $packet-table = make(<stretchy-vector>);

define method recursive-summary (frame :: <header-frame>) => (res :: <string>)
  concatenate(summary(frame), "/", recursive-summary(frame.payload));
end;

define method recursive-summary (frame :: <frame>) => (res :: <string>)
  summary(frame);
end;

define function recv-frame (frame :: <object>)
  let id = $packet-table.size;
  add!($packet-table, pair(frame, id));
  maybe-get-summary(id, frame);
end;

define function latest-payload (frame :: <container-frame>) => (res :: <container-frame>)
  maybe-last(frame, frame)
end;


define method maybe-last (frame :: <header-frame>, outer :: <container-frame>)
  => (res :: <container-frame>)
  maybe-last(frame.payload, frame)
end;

define method maybe-last (frame :: <container-frame>, outer :: <container-frame>)
  => (res :: <container-frame>)
  frame
end;

define method maybe-last (frame :: <raw-frame>, outer :: <container-frame>)
  => (res :: <container-frame>)
  outer
end;

define method find-addresses (frame :: <header-frame>) => (source, destination)
  let (child-a, child-b) = find-addresses(frame.payload);
  if (child-a & child-b)
    values(child-a, child-b)
  else
    next-method()
  end
end;

define method find-addresses (frame) => (source, destination)
  values(source-address(frame), destination-address(frame))
end;

define method source-address (frame :: type-union(<raw-frame>, <container-frame>)) => (res)
  #f;
end;

define method destination-address (frame :: type-union(<raw-frame>, <container-frame>)) => (res)
  #f;
end;


define function maybe-get-summary (id :: <integer>, frame :: <object>)
  let queue = stream-resource.sse-queue;
  let lock = stream-resource.sse-queue-lock;
  let notification = stream-resource.sse-queue-notification;
  if (~ *filter-expression* | matches?(frame, *filter-expression*))
    with-lock (lock)
      if (queue.empty?)
        release-all(notification)
      end;
      let last-data = frame.latest-payload;
      let (source, target) = find-addresses(frame);
      let data = struct(packetid:, id,
                        source: as(<string>, source),
                        destination: as(<string>, target),
                        protocol: last-data.frame-name,
                        content: last-data.summary.quote-html);
      let str = make(<string-stream>, direction: #"output");
      encode-json(str, list(data));
      let json = str.stream-contents;
      dbg("inserting data: %s\n", json);
      push-last(queue, concatenate("data: ", json));
    end;
  end;
end;

define method execute (c :: <open-command>, #rest args, #key)
  let interface = args[0];
  block ()
    let mac = mac-address("00:de:ad:be:ef:00");
    let int = make(<ethernet-interface>, name: interface, promiscuous?: #t);
    assert(int.pcap-t);
    $interface-table[as(<symbol>, interface)] := int;
    let ethernet-layer = make(<ethernet-layer>,
                              ethernet-interface: int,
                              default-mac-address: mac);
    make(<thread>, function: curry(toplevel, int));
    let ethernet-socket = create-raw-socket(ethernet-layer);
    let sum = make(<closure-node>, closure: recv-frame);
    connect(ethernet-socket, sum);
    #("connected!")
  exception (c :: <condition>)
    list(struct(error: quote-html(format-to-string("Cannot open interface %=: %=", interface, c))))
  end
end;


define class <close-command> (<command>)
end;
make(<close-command>, name: #"close", description: "Closes a network interface", signature: "<interface>");

define method execute (c :: <close-command>, #rest args, #key)
  block ()
    let interface = as(<symbol>, args[0]);
    let int = $interface-table[interface];
    remove-key!($interface-table, interface);
    int.running? := #f;
    #("shutdown!")
  exception (c :: <condition>)
    list(struct(error: quote-html(format-to-string("Cannot close interface: %=", c))))
  end
end;

define class <details-command> (<command>)
end;
make(<details-command>, name: #"details", description: "Shows details of a given packet", signature: "<packet-identifier>");

define method summarize-layers (frame :: <header-frame>) => (res :: <collection>)
  pair(frame.summary, frame.payload.summarize-layers)
end;

define method summarize-layers (frame :: type-union(<raw-frame>, <container-frame>)) => (res :: <collection>)
  list(frame.summary)
end;

define method execute (c :: <details-command>, #rest args, #key)
  block ()
    let pint = string-to-integer(args[0]);
    let frame = $packet-table[pint].head;
    let stream = make(<string-stream>, direction: #"output");
    let hex = hexdump(stream, frame.packet);
    let data = stream.stream-contents;
    let hexd = split(data, '\n', remove-if-empty?: #t);
    let layers = frame.summarize-layers;
    list(struct(hex:, hexd, tree: map(quote-html, layers), packetid:, pint))
  exception (c :: <condition>)
    list(struct(error: quote-html(format-to-string("Failed to get details: %=", c))))
  end
end;

define class <treedetails-command> (<command>)
end;
make(<treedetails-command>, name: #"treedetails", description: "Shows container frame of given layer", signature: "<packet-identifier> <layer-identifier>");

define method find-layer (frame :: <frame>, count == 0) => (frame :: <frame>)
  dbg("finding layer1 %d %=\n", count, frame);
  frame
end;

define method find-layer (frame :: <header-frame>, count == 0) => (frame :: <frame>)
  frame
end;

define method find-layer (frame :: <frame>, count :: <integer>) => (frame :: <frame>)
  error("no such layer in frame")
end;

define method find-layer (frame :: <header-frame>, count :: <integer>) => (frame :: <frame>)
  dbg("finding layer2 %d %=\n", count, frame);
  find-layer(frame.payload, count - 1)
end;

define method frame-children-generator (a-frame :: <header-frame>)
  let ffs = sorted-frame-fields(a-frame);
  copy-sequence(ffs, end: ffs.size - 1);
end;

define method frame-children-generator (frame-field :: <frame-field>)
  frame-children-generator(frame-field.value);
end;

define method frame-children-generator (frame-field :: <repeated-frame-field>)
  frame-field.frame-field-list
end;

define method frame-children-generator (ff :: <rep-frame-field>)
  frame-children-generator(ff.frame)
end;

define method frame-children-generator (collection :: <collection>)
  collection
end;

define method frame-children-generator (a-frame :: <container-frame>)
  sorted-frame-fields(a-frame)
end;

define method frame-print-label (frame-field :: <frame-field>)
  if (frame-field.field.field-name = #"payload")
    format-to-string("%s", frame-print-label(frame-field.value))
  else
    format-to-string("%s: %s", frame-field.field.field-name, frame-print-label(frame-field.value))
  end;
end;

define method frame-print-label (mframe :: <rep-frame-field>)
  frame-print-label(mframe.frame);
end;
define method frame-print-label (frame :: <collection>)
  format-to-string("(%d elements)", frame.size)
end;

define method frame-print-label (frame :: <container-frame>)
  format-to-string("%s %s", frame.frame-name, frame.summary);
end;

define method frame-print-label (frame :: <leaf-frame>)
  format-to-string("%=", frame);
end;

define method frame-print-label (frame :: <object>)
  as(<string>, frame);
end;

define method frame-print-label (frame :: <raw-frame>)
  format-to-string("Additional data: %d bytes", frame.data.size)
end;


define method execute (c :: <treedetails-command>, #rest args, #key)
  block ()
    let pid = string-to-integer(args[0]);
    let lid = string-to-integer(args[1]);
    let frame = $packet-table[pid].head;
    let lay = find-layer(frame, lid);
    let strings = map(frame-print-label, lay.frame-children-generator);
    list(struct(fields:, strings))
  exception (c :: <condition>)
    list(struct(error: quote-html(format-to-string("Failed treedetails: %=", c))))
  end;
end;

define variable *filter-expression* :: false-or(<filter-expression>) = #f;

define class <filter-command> (<command>)
end;
make(<filter-command>, name: #"filter", description: "Filters the packet capture", signature: "<filter-expression>");

define method execute (c :: <filter-command>, #rest args, #key)
  let expression = args[0];
  block ()
    if (expression = "delete")
      *filter-expression* := #f;
    else
      let filter = parse-filter(expression);
      *filter-expression* := filter;
    end;
    for (frame in $packet-table)
      maybe-get-summary(frame.tail, frame.head)
    end;
    #("successfully installed filter")
  exception (c :: <condition>)
    *filter-expression* := #f;
    list(struct(error: quote-html(format-to-string("Cannot set filter %=: %=", expression, c))))
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
