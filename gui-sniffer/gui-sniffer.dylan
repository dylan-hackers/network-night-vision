Module:    gui-sniffer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define constant $packet-list-lock = make(<lock>);
define method frame-children-predicate (frame :: <leaf-frame>)
  #f
end;

define method frame-children-predicate (frame :: <container-frame>)
  #t
end;

define method frame-children-predicate (collection :: <collection>)
  collection.size > 0
end;

define method frame-children-predicate (raw-frame :: <raw-frame>)
  raw-frame.data.size > 0
end;

define method frame-children-predicate (object :: <object>)
  #f
end;

define method frame-children-predicate (frame-field :: <frame-field>)
  frame-children-predicate(frame-field.value);
end;

define method frame-children-predicate (frame-field :: <repeated-frame-field>)
  frame-field.frame-field-list.size > 0
end;

define method frame-children-predicate (ff :: <rep-frame-field>)
  frame-children-predicate(ff.frame)
end;

define method frame-children-generator (collection :: <collection>)
  collection
end;

define method frame-children-generator (a-frame :: <container-frame>)
  sorted-frame-fields(a-frame)
end;

define class <raw-frame-element> (<position-mixin>)
  constant slot raw-frame :: <raw-frame>, required-init-keyword: raw-frame:;
  constant slot hex-dump-row :: <string>, required-init-keyword: value:;
end;

define method frame-children-generator (raw-frame :: <raw-frame>)
  let out = hexdump(raw-frame.data);
  let lines = split(out, '\n');
  if (lines[lines.size - 1] = "")
    lines := copy-sequence(lines, end: lines.size - 1)
  end;

  let children = make(<stretchy-vector>);

  for (line in lines, offset from 0 by 16 * 8)
    let length = min(16 * 8, raw-frame.data.size * 8 - offset);
    add!(children, make(<raw-frame-element>,
                        start: offset,
                        length: length,
                        end: offset + length,
                        raw-frame: raw-frame,
                        value: line));
  end;
  children;
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

define method frame-root-generator (frame :: <header-frame>)
  add!(frame-root-generator(payload(frame)), get-frame-field(#"payload", frame));
end;

define method frame-root-generator (frame :: <frame>)
  #();
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

define method frame-print-label (frame :: <raw-frame-element>)
  frame.hex-dump-row;
end;

define method print-source (frame :: <frame-with-metadata>)
  let source = find-source-address(frame.real-frame);
  if (source)
    as(<string>, source)
  else
    "Unknown"
  end;
end;

define method find-source-address (frame :: <header-frame>)
  find-source-address(frame.payload) | next-method();
end;

define method find-source-address (frame)
  source-address(frame);
end;

define method source-address (frame :: type-union(<raw-frame>, <container-frame>)) => (res)
  #f;
end;

define method print-destination (frame :: <frame-with-metadata>)
  let destination = find-destination-address(frame.real-frame);
  if (destination)
    as(<string>, destination);
  else
    "Unknown"
  end;
end;

define method find-destination-address (frame :: <header-frame>)
  find-destination-address(frame.payload) | next-method();
end;

define method find-destination-address (frame)
 destination-address(frame)
end;

define method destination-address (frame :: type-union(<raw-frame>, <container-frame>)) => (res)
  #f
end;

define method print-protocol (frame :: <frame-with-metadata>)
  let proto = find-protocol-name(frame.real-frame);
  if (proto)
    proto.frame-name;
  else
    "Unknown"
  end;
end;

define method find-protocol-name (frame :: <header-frame>)
  find-protocol-name(frame.payload) | next-method()
end;

define method find-protocol-name (frame :: <raw-frame>)
  #f
end;

define method find-protocol-name (frame :: <container-frame>)
  frame;
end;

define method print-info (frame :: <frame-with-metadata>)
  find-print-info(frame.real-frame)
end;

define method find-print-info (frame :: <header-frame>) => (res)
  find-print-info(frame.payload) | next-method()
end;

define method find-print-info (frame :: type-union(<raw-frame>, <container-frame>))
  let cur = summary(frame);
  if (cur = format-to-string("%=", frame.object-class))
    #f
  else
    cur;
  end;
end;

define method print-number (frame :: <frame-with-metadata>)
  frame.number;
end;

define generic print-time (gui :: <gui-sniffer-frame>, frame :: <frame-with-metadata>);
define method print-time (gui :: <gui-sniffer-frame>, frame :: <frame-with-metadata>)
  let diff = frame.receive-time - gui.first-packet-arrived;
  let (days, hours, minutes, seconds, microseconds)
    = decode-duration(diff);
  let secs = (((days * 24 + hours) * 60) + minutes) * 60 + seconds;
  concatenate(integer-to-string(secs), ".", integer-to-string(truncate/(microseconds, 1000), size: 3));
end;

define generic apply-filter (frame :: <gui-sniffer-frame>);
define method apply-filter (frame :: <gui-sniffer-frame>)
  let filter-string = gadget-value(frame.filter-field);
  let old = frame.filter-expression;
  if (filter-string.size > 0)
    frame.filter-expression := 
      block ()
        gadget-label(frame.sniffer-status-bar) := "Applying packet filter";
        parse-filter(filter-string);
      exception (c :: <error>)
        gadget-label(frame.sniffer-status-bar) := "Syntax error in filter expression";
        #f
      end;
        
    if (old ~= frame.filter-expression & every?(curry(\~=, filter-string), frame.filter-history))
      frame.filter-history := add!(frame.filter-history, filter-string);
      gadget-items(frame.filter-field) := frame.filter-history;
    end;
  else
    frame.filter-expression := #f;
    gadget-label(frame.sniffer-status-bar) := "Clearing packet filter";
  end;
  if (old ~= frame.filter-expression)
    filter-packet-table(frame);
  end;
end;

define function filter-packet-table (frame :: <gui-sniffer-frame>)
  with-lock($packet-list-lock)
    let shown-packets
      = if (frame.filter-expression)
          choose-by(rcurry(matches?, frame.filter-expression),
                    map(real-frame, frame.network-frames),
                    frame.network-frames)
        else
          copy-sequence(frame.network-frames)
        end;
    unless (shown-packets = gadget-items(frame.packet-table))
      gadget-items(frame.packet-table) := shown-packets;
      show-packet(frame);
    end;
  end;
end;

define function show-packet (frame :: <gui-sniffer-frame>)
  let current-packet = current-packet(frame);
  show-packet-tree(frame, current-packet);
  current-packet & show-hexdump(frame, current-packet.packet);
  redisplay-window(frame.packet-hex-dump);
end;

define function show-packet-hexdump
    (frame :: <gui-sniffer-frame>, network-packet)
  frame.packet-hex-dump.gadget-text := hexdump(network-packet.packet);
end;

define function show-packet-tree (frame :: <gui-sniffer-frame>, packet)
  frame.packet-tree-view.tree-control-roots
    := if (packet)
         add!(frame-root-generator(packet), packet);
       else
         #[]
       end;
end;

define method find-frame-field (frame :: <container-frame>, search :: type-union(<container-frame>, <raw-frame>))
 => (res :: false-or(type-union(<frame-field>, <rep-frame-field>)))
  block(ret)
    for (ff in sorted-frame-fields(frame))
      if (ff.value == search)
        ret(ff)
      end;
      if (instance?(ff.value, <collection>))
        let framefield = choose-by(curry(\=, search),
                                   ff.value,
                                   ff.frame-field-list);
        if (framefield.size = 1) ret(framefield[0]) end;
      end;
    end;
    #f;
  end;
end;

define method compute-absolute-offset (frame :: type-union(<container-frame>, <raw-frame>), relative-to)
  if (frame.parent & frame ~= relative-to)
    let ff = find-frame-field(frame.parent, frame);
    compute-absolute-offset(ff, relative-to);
  else
    0;
  end;
end;
define method compute-absolute-offset (ff :: <rep-frame-field>, relative-to)
 => (res :: <integer>)
  start-offset(ff) + compute-absolute-offset(ff.parent-frame-field, relative-to);
end;
define method compute-absolute-offset (frame-field :: <frame-field>, relative-to)
 => (res :: <integer>)
  start-offset(frame-field) + compute-absolute-offset(frame-field.frame, relative-to)
end;

define method compute-absolute-offset (ff :: <raw-frame-element>, relative-to)
 => (res :: <integer>)
  start-offset(ff) + compute-absolute-offset(ff.raw-frame, relative-to);
end;

define method compute-length (frame :: <header-frame>) => (res :: <integer>)
  start-offset(sorted-frame-fields(frame).last)
end;

define method compute-length (frame :: <frame>) => (res :: <integer>)
  frame-size(frame)
end;

define method compute-length (frame-field :: <position-mixin>) => (res :: <integer>)
  frame-field.length
end;

define method compute-length (frame-field :: <frame-field>) => (res :: <integer>)
  if (frame-field.field.field-name = #"payload")
    compute-length(frame-field.value)
  else
    frame-field.length;
  end
end;

define method find-frame-at-offset (frame :: <container-frame>, offset :: <integer>)
 => (result-frame)
  block(ret)
    for (ff in sorted-frame-fields(frame))
      if ((start-offset(ff) <= offset) & (end-offset(ff) >= offset))
        //format-out("looking in %s, offset %d\n", ff.field.field-name, offset - start-offset(ff));
        ret(find-frame-at-offset(ff.value, offset - start-offset(ff)));
      end;
    end;
  end;
end;

define method find-frame-at-offset (frame :: <collection>, offset :: <integer>)
  let start = 0;
  block(ret)
    for (ele in frame, i from 0)
      if ((start <= offset) & (frame-size(ele) >= offset))
        //format-out("looking in %d, offset %d\n", i, offset - start);
        ret(find-frame-at-offset(ele, offset - start));
      end;
      start := start + frame-size(ele);
    end;
  end;
end;

define method find-frame-at-offset (frame :: <leaf-frame>, offset :: <integer>)
  frame;
end;

define function highlight-hex-dump (mframe :: <gui-sniffer-frame>)
  let packet = mframe.packet-table.gadget-value;
  let tree = mframe.packet-tree-view;
  let selected-packet = tree.gadget-items[tree.gadget-selection[0]];

  let start-highlight = compute-absolute-offset(selected-packet, packet.real-frame);
  let end-highlight = start-highlight + compute-length(selected-packet);
  format-out("start highlight %d end highlight %d\n", start-highlight, end-highlight);
  set-highlight(mframe, start-highlight, end-highlight);
  redisplay-window(mframe.packet-hex-dump);

end;

define variable *count* :: <integer> = 0;
define method counter ()
  *count* := *count* + 1;
  *count*;
end;

define function show-about-box (x)
  start-dialog(make(<about-box>))
end;

define variable *debugging?* = #t;

define method safe(func :: <function>)
  method(#rest args)
    block(return)
      let handler <error>
        = method(condition, next-handler)
              if (*debugging?*)
                next-handler()
              else
                return("broken")
              end;
          end;
      apply(func, args)
    end
  end
end;

define method safe-p(func :: <function>)
  method(#rest args)
    block(return)
      let handler <error>
        = method(condition, next-handler)
              if(*debugging?*)
                next-handler()
              else
                return()
              end;
          end;
      apply(func, args)
    end
  end
end;

define constant $text-style = make(<text-style>, family: #"fix", size: 8);

define frame <gui-sniffer-frame> (<simple-frame>, deuce/<basic-editor-frame>, <filter>)
  slot network-frames :: <stretchy-vector> = make(<stretchy-vector>);
  slot filter-expression = #f;
  slot ethernet-layer = #f;
  slot ip-layer = #f;
  slot listening-socket = #f;
  slot first-packet-arrived :: false-or(<date>) = #f;
  slot filter-history :: <list> = make(<list>);

  pane filter-field (frame)
    make(<combo-box>,
         label: "Filter expression",
         value-changed-callback: method(x) apply-filter(frame) end,
         activate-callback: method(x) apply-filter(frame) end,
         text-style: $text-style,
         items: frame.filter-history);

  pane filter-pane (frame)
    horizontally()
      make(<label>, label: "Filter: ");
      frame.filter-field;
    end;

  pane packet-table (frame)
    make(<table-control>,
         headings: #("No", "Time", "Source", "Destination", "Protocol", "Info"),
         generators: list(safe(print-number),
                          safe(curry(print-time, frame)),
                          safe(print-source),
                          safe(print-destination),
                          safe(print-protocol),
                          safe(print-info)),
         widths: #[30, 60, 150, 150, 100, 500],
         items: #[],
         text-style: $text-style,
         popup-menu-callback: display-popup-menu,
         value-changed-callback: safe-p(method(x) show-packet(frame) end));


  pane packet-tree-view (frame)
    make(<tree-control>,
         roots: #[],
         label-key: safe(frame-print-label),
         children-generator: safe(frame-children-generator),
         children-predicate: safe-p(frame-children-predicate),
         text-style: $text-style,
         value-changed-callback: safe-p(method(x) highlight-hex-dump(frame) end));

  pane packet-hex-dump (frame)
    make(<deuce-pane>,
         frame: frame,
         read-only?: #t,
         tab-stop?: #t,
         lines: 20,
         columns: 100,
         scroll-bars: #"vertical",
         text-style: $text-style);
/*
       make(<text-editor>,
            read-only?: #t,
            tab-stop?: #t,
            lines: 20,
            columns: 100,
//            scroll-bars: #"vertical",
            text-style: make(<text-style>, family: #"fix")); */
  pane nnv-shell (frame)
    make-nnv-shell-pane(context: frame);

  pane sniffer-status-bar (frame)
    make(<status-bar>, label: "Network Night Vision");

  pane open-button (frame)
    make(<push-button>, label: "open",
         activate-callback: method(x) open-pcap-file(frame) end);
  pane save-button (frame)
    make(<push-button>, label: "save",
         activate-callback: method(x) save-pcap-file(frame) end);
  pane play-button (frame)
    make(<push-button>, label: "play",
         activate-callback: method(x) open-interface(frame) end);
  pane stop-button (frame)
    make(<push-button>, label: "stop", enabled?: #f,
         activate-callback: method(x) close-interface(frame) end);
    
  pane sniffer-tool-bar (frame)
    make(<tool-bar>,
         height: 18,
         resizable?: #f,
         child: horizontally ()
                  frame.open-button;
                  frame.save-button;
                  make(<separator>, orientation: #"vertical");
                  frame.play-button;
                  frame.stop-button;
                end);

  layout (frame) vertically()
                   frame.filter-pane;
                   make(<column-splitter>,
                        children: vector(frame.packet-table,
                                         frame.packet-tree-view,
                                         scrolling (scroll-bars: #"both")
                                           frame.packet-hex-dump
                                         end,
                                         scrolling (scroll-bars: #"both")
                                           frame.nnv-shell
                                         end
                                         ));
                 end;

  tool-bar (frame) frame.sniffer-tool-bar;
  command-table (frame) *gui-sniffer-command-table*;
  status-bar (frame) frame.sniffer-status-bar;
  keyword title: = "Network Night Vision";
  //keyword icon: = $icons["nnv-small"];
end;

define command-table *file-command-table* (*global-command-table*)
  menu-item "Open pcap file..." = open-pcap-file;
  menu-item "Save to pcap file..." = save-pcap-file;
  menu-item "About" = show-about-box;
  menu-item "Exit" = exit-application;
end;

define command-table *interface-command-table* (*global-command-table*)
  menu-item "Start..." = open-interface;
  menu-item "Stop" = close-interface;
end;

define command-table *gui-sniffer-command-table* (*global-command-table*)
  menu-item "File" = *file-command-table*;
  menu-item "Capture" = *interface-command-table*;
end;

define function reinject-packet(frame :: <gui-sniffer-frame>)
  push-data(frame.the-output, current-packet(frame))
end;

define constant $transform-from-bv = compose(byte-vector-to-float-be, data);
define constant $transform-to-bv = compose(big-endian-unsigned-integer-4byte, float-to-byte-vector-be);

define inline function stack (#rest frames)
  for (i from 1 below frames.size)
    frames[i - 1].payload := frames[i]
  end;
  frames[0]
end;

define inline function ethernet-frame (#rest args)
  apply(make, <ethernet-frame>, args)
end;

define inline function ipv4-frame (#rest args)
  apply(make, <ipv4-frame>, args)
end;

define inline function tcp-frame (#rest args)
  apply(make, <tcp-frame>, args)
end;

define method tcpkill (node :: <gui-sniffer-frame>);
  let data = current-packet(node);
  let incoming-ip = data.payload;
  let incoming-tcp = incoming-ip.payload;
  let sequence = $transform-from-bv(incoming-tcp.acknowledgement-number);
  push-data
    (node.the-output,
     stack(ethernet-frame(source-address: data.destination-address,
                          destination-address: data.source-address),
           ipv4-frame(source-address: incoming-ip.destination-address,
                      destination-address: incoming-ip.source-address),
           tcp-frame(source-port: incoming-tcp.destination-port,
                     destination-port: incoming-tcp.source-port,
                     rst: 1,
                     sequence-number: $transform-to-bv(sequence),
                     acknowledgement-number: $transform-to-bv(0.0s0))));
  push-data
    (node.the-output,
     stack(ethernet-frame(source-address: data.source-address,
                          destination-address: data.destination-address),
           ipv4-frame(source-address: incoming-ip.source-address,
                        destination-address: incoming-ip.destination-address),
           tcp-frame(source-port: incoming-tcp.source-port,
                     destination-port: incoming-tcp.destination-port,
                     rst: 1,
                     sequence-number: $transform-to-bv($transform-from-bv(incoming-tcp.sequence-number) 
                                                        + byte-offset(incoming-tcp.payload.frame-size)),
                     acknowledgement-number: $transform-to-bv(0.0s0))));
end;

define method ping-source (node :: <gui-sniffer-frame>)
  let data = current-packet(node);
  let icmp = icmp-frame(code: 0, icmp-type: 8,
                        payload: read-frame(<raw-frame>, "123412341234123412341234123412341234123412341234"));
  send(node.ip-layer, data.payload.source-address, icmp);
end;

define command-table *popup-menu-command-table* (*global-command-table*)
  menu-item "Filter Packet-Source" = filter-source;
  menu-item "Filter Packet-Destination" = filter-destination; 
  menu-item "Follow Connection" = follow-connection;
  menu-item "Re-inject Packet" = reinject-packet;
  menu-item "Kill TCP Connection" = tcpkill;
  menu-item "Ping Source" = ping-source;
end;

define method display-popup-menu (sheet, target, #key x, y)
  let frame = sheet.sheet-frame;
  let menu = make-menu-from-command-table-menu
               (command-table-menu(*popup-menu-command-table*),
                frame, frame-manager(frame),
                command-table: *popup-menu-command-table*,
                owner: frame);
  display-menu(menu);
end;

define method filter-source (frame :: <gui-sniffer-frame>)
  filter-by(source-address, frame);
end;

define method filter-destination (frame :: <gui-sniffer-frame>)
  filter-by(destination-address, frame);
end;

define function current-packet (frame :: <gui-sniffer-frame>)
  let current-packet = frame.packet-table.gadget-value;
  current-packet & real-frame(current-packet)
end;

define function filter-by (filter-method :: <function>, frame :: <gui-sniffer-frame>)
  let layer = find-decent-layer(filter-method, current-packet(frame));
  let (field, frame-name) = find-protocol-field(frame-name(layer), filter-method.debug-name);
  let filter = concatenate(frame-name, ".", filter-method.debug-name, " = ",
                           as(<string>, filter-method(layer)));
  frame.filter-expression := make(<field-equals>,
                                  frame: as(<symbol>, frame-name),
                                  name: as(<symbol>, filter-method.debug-name),
                                  value: filter-method(layer),
                                  field: field);
  filter-packet-table(frame);
//  gadget-value(frame.filter-field) := filter;
end;

define method find-decent-layer(filter-method :: <function>, frame :: <header-frame>)
  find-decent-layer(filter-method, frame.payload) | next-method();
end;

define method find-decent-layer(filter-method :: <function>, frame :: type-union(<container-frame>, <raw-frame>))
  if (filter-method(frame))
    frame;
  end;
end;
define method real-payload (f :: <header-frame>)
  real-payload(f.payload)
end;
define method real-payload (f :: type-union(<container-frame>, <raw-frame>))
  f;
end;

define method follow-connection (frame :: <gui-sniffer-frame>)
  let current-packet = frame.packet-table.gadget-value;
  if (current-packet) current-packet := real-frame(current-packet) end;
  let filters = create-connection-filter(current-packet);
  gadget-value(frame.filter-field) := filters;
  apply-filter(frame);
  let packets = map(real-frame, frame.packet-table.gadget-items);
  let payloads = map(method(x) real-payload(x).data end, packets);
  show-payloads(apply(concatenate, payloads), owner: frame);
end;

define method show-payloads
  (text, #key title = "Following Connection", owner)
 => ()
  let stream = make(<string-stream>, direction: #"output");
  let mytext = #f;
  block()
    for (byte in text)
      if ((byte >= 32 & byte < 128) | (byte = #xa) | (byte = #xd)) // lame, I know
        format(stream, "%s", as(<character>, byte))
      else
        format(stream, ".")
      end;
    end;
    mytext := stream-contents(stream);
  cleanup
    close(stream)
  end;
  //format-out("Show payload %s\n", mytext);
  let text-editor = make(<text-editor>,
                         read-only?: #t,
                         tab-stop?: #t,
                         lines: 60,
                         columns: 100,
                         scroll-bars: #"vertical",
                         text: mytext,
                         text-style: make(<text-style>, family: #"fix"));
  let dialog = make(<dialog-frame>,
                    title: title,
                    owner: owner,
                    layout: text-editor);
  start-dialog(dialog)
end;

define method create-connection-filter (frame :: <header-frame>)
  create-connection-filter(frame.payload) | next-method();
end;

define function generate-filter (protocol, key1, value1, key2, value2)
  concatenate("((", protocol, ".", key1, " = ", value1, ") & ",
              "(", protocol, ".", key2, " = ", value2, ")) | ",
              "((", protocol, ".", key2, " = ", value1, ") & ",
              "(", protocol, ".", key1, " = ", value2, "))");
end;
define method create-connection-filter (frame :: <ethernet-frame>)
  next-method() |
   generate-filter(frame.frame-name,
                   "source-address", as(<string>, frame.source-address),
                   "destination-address", as(<string>, frame.destination-address));
end;

define method create-connection-filter (frame :: <ipv4-frame>)
  let next-filter = create-connection-filter(frame.payload);
  let ip-filter
    = generate-filter(frame.frame-name,
                      "source-address", as(<string>, frame.source-address),
                      "destination-address", as(<string>, frame.destination-address));
  if (next-filter)
    concatenate("(", next-filter, ") & (", ip-filter, ")");
  else
    ip-filter;
  end;
end;

define method create-connection-filter (frame :: type-union(<tcp-frame>, <udp-frame>))
  generate-filter(frame.frame-name,
                  "source-port", integer-to-string(frame.source-port),
                  "destination-port", integer-to-string(frame.destination-port));
end;

define method create-connection-filter (frame)
  #f;
end;

define method open-pcap-file (frame :: <gui-sniffer-frame>)
  let file = choose-file(frame: frame, direction: #"input");
  if (file)
    reinit-gui(frame);
    let file-stream = make(<file-stream>, locator: file, direction: #"input");
    let pcap-reader = make(<pcap-file-reader>, stream: file-stream);
    connect(pcap-reader, frame);
    toplevel(pcap-reader);
    disconnect(pcap-reader, frame);
    gadget-label(frame.sniffer-status-bar) := concatenate("Opened ", file);
    close(file-stream);
  end;
end;

define method save-pcap-file (frame :: <gui-sniffer-frame>)
  let file = choose-file(frame: frame, direction: #"output");
  if (file)
    let file-stream = make(<file-stream>,
                           locator: file,
                           direction: #"output",
                           if-exists: #"replace");
    let pcap-writer = make(<pcap-file-writer>, stream: file-stream);
    connect(frame, pcap-writer);
    do(curry(push-data, frame.the-output),
       map(method(x)
             let time-diff = x.receive-time - make(<date>, year: 1970, month: 1, day: 1);
             make(<pcap-packet>,
                  timestamp: make-unix-time(time-diff),
                  payload: x.real-frame)
           end, frame.network-frames));
    disconnect(frame, pcap-writer);
    gadget-label(frame.sniffer-status-bar) := concatenate("Wrote ", file);
    close(file-stream);
  end;
end;

define method open-interface (frame :: <gui-sniffer-frame>)
  let (interface-name, promiscuous?) = prompt-for-interface(owner: frame);
  if (interface-name)
    format-out("Listening on interface %=\n", interface-name);
    let ethernet-layer
      = build-ethernet-layer(interface-name, promiscuous?: promiscuous?);
    let ethernet-socket = create-raw-socket(ethernet-layer);
    connect(ethernet-socket, frame);
    connect(frame, ethernet-socket);
    frame.ip-layer := build-ip-layer(ethernet-layer, ip-address: ipv4-address("192.168.0.69"));
    reinit-gui(frame);
    frame.ethernet-layer := ethernet-layer;
    frame.listening-socket := ethernet-socket;
    gadget-label(frame.sniffer-status-bar) := concatenate("Capturing ", interface-name);
    command-enabled?(open-pcap-file, frame) := #f;
    gadget-enabled?(frame.open-button) := #f;
    command-enabled?(open-interface, frame) := #f;
    gadget-enabled?(frame.play-button) := #f;
    command-enabled?(close-interface, frame) := #t;
    gadget-enabled?(frame.stop-button) := #t;
  end;
  format-out("finished open interface\n");
end;

define method close-interface (frame :: <gui-sniffer-frame>)
  frame.ethernet-layer.ethernet-interface.running? := #f;
  gadget-label(frame.sniffer-status-bar) := "Stopped capturing";
  disconnect(frame.listening-socket, frame);
  disconnect(frame, frame.listening-socket);
  frame.listening-socket := #f;
  command-enabled?(open-pcap-file, frame) := #t;
  gadget-enabled?(frame.open-button) := #t;
  command-enabled?(open-interface, frame) := #t;
  gadget-enabled?(frame.play-button) := #t;
  command-enabled?(close-interface, frame) := #f;
  gadget-enabled?(frame.stop-button) := #f;
end;

define method prompt-for-interface
  (#key title = "Please specify interface", owner)
 => (interface-name :: false-or(<string>), promiscuous? :: <boolean>)
  let devices = find-all-devices();
  let interfaces = make(<list-box>, items: map(device-name, devices));
  let promiscuous? = make(<check-box>, items: #("promiscuous"), selection: #[0]);
  let interface-selection-dialog
    = make(<dialog-frame>,
           title: title,
           owner: owner,
           layout: horizontally()
                     interfaces;
                     promiscuous?
                   end);
  if (start-dialog(interface-selection-dialog))
    values(gadget-value(interfaces), size(gadget-value(promiscuous?)) > 0)
  end;
end;

define constant $about-text
  = concatenate("Network Night Vision 0.0.2\n",
                "(c) 2005 - 2007 Andreas Bogk, Hannes Mehnert\n",
                "All Rights Reserved. Free for non-commercial use.\n",
                "\n",
                "http://www.networknightvision.com/");

define frame <about-box> (<dialog-frame>)
  pane splash-screen-pane (frame)
    make(<text-editor>, text: $about-text, read-only?: #t, lines: 5, columns: 50);
  layout (frame)
    frame.splash-screen-pane;
  keyword title: = "About Network Night Vision 0.0.2";
end;


define method reinit-gui (frame :: <gui-sniffer-frame>)
  frame.first-packet-arrived := #f;
  *count* := 0;
  with-lock ($packet-list-lock)
    frame.network-frames := make(<stretchy-vector>);
    gadget-items(frame.packet-table) := #();
  end;
  show-packet(frame);
end;

define class <frame-with-metadata> (<object>)
  constant slot real-frame :: <container-frame>, required-init-keyword: frame:;
  constant slot number :: <integer> = counter();
  constant slot receive-time :: <date> = current-date(), init-keyword: receive-time:;
end;

define method push-data-aux (input :: <push-input>,
                             node :: <gui-sniffer-frame>,
                             frame :: <frame>)
  let frame-with-meta =
    if (frame.parent & instance?(frame.parent, <pcap-packet>))
      make(<frame-with-metadata>,
           frame: frame,
           receive-time: decode-unix-time(frame.parent.timestamp))
    else
      make(<frame-with-metadata>, frame: frame);
    end;
  unless (node.first-packet-arrived)
    node.first-packet-arrived := frame-with-meta.receive-time;
  end;
  with-lock($packet-list-lock)
    add!(node.network-frames, frame-with-meta);
    if (~ node.filter-expression | matches?(frame, node.filter-expression))
      add-item(node.packet-table, make-item(node.packet-table, frame-with-meta));
      // if (always-scroll)
      let (left, top, right, bottom) = box-edges(node.packet-table);
      let (x, y) = scroll-position(node.packet-table);
      set-scroll-position(node.packet-table, x, bottom); 
    end;
  end;
end;

define constant $icons = make(<string-table>);

define function initialize-icons ()
/*
  local method load-and-register-item (name, size)
    $icons[as-lowercase(name)]
      := read-image-as(<win32-icon>, as(<byte-string>, name), #"icon", width: size, height: size);
  end;
  load-and-register-item("PLAY", 16);
  load-and-register-item("OPEN", 16);
  load-and-register-item("SAVE", 16);
  load-and-register-item("STOP", 16);
  load-and-register-item("NNV", 32);
  $icons["nnv-small"]
    := read-image-as(<win32-icon>, as(<byte-string>, "NNV"), #"small-icon");
*/
end;







