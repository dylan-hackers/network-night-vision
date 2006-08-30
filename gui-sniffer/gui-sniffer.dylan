Module:    gui-sniffer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define method frame-children-predicate (frame :: <leaf-frame>)
  #f
end;

define method frame-children-predicate (frame :: <container-frame>)
  #t
end;

define method frame-children-predicate (collection :: <collection>)
  collection.size > 0
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

define method frame-root-generator (frame :: <ethernet-frame>)
  add!(next-method(), frame);
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

define method print-source (frame :: <frame-with-metadata>)
  print-source(frame.real-frame) | "Unknown"
end;

define method print-source (frame :: <header-frame>)
  print-source(frame.payload);
end;

define method print-source (frame :: <frame>)
  #f;
end;

define method print-source (frame :: <ethernet-frame>)
  next-method() | as(<string>, frame.source-address)
end;

define method print-source (frame :: <ipv4-frame>)
  next-method() | as(<string>, frame.source-address)
end;

/*define method print-source (frame :: <arp-frame>)
  as(<string>, frame.source-ip-address)
end;*/

define method print-source (frame :: <ieee80211-management-frame>)
  next-method() | as(<string>, frame.source-address)
end;

define method print-destination (frame :: <frame-with-metadata>)
  print-destination(frame.real-frame) | "Unknown"
end;

define method print-destination (frame :: <header-frame>)
  print-destination(frame.payload);
end;

define method print-destination (frame :: <frame>)
  #f;
end;

define method print-destination (frame :: <ethernet-frame>)
  next-method() | as(<string>, frame.destination-address)
end;

define method print-destination (frame :: <ipv4-frame>)
  next-method() | as(<string>, frame.destination-address)
end;

define method print-destination (frame :: <ieee80211-management-frame>)
  next-method() | as(<string>, frame.destination-address)
end;

/*define method print-destination (frame :: <arp-frame>)
  if (frame.target-mac-address ~= mac-address("00:00:00:00:00:00"))
    as(<string>, frame.target-ip-address)
  else
    "Broadcast"
  end;
end;*/

define method print-protocol (frame :: <frame-with-metadata>)
  print-protocol(frame.real-frame) | "Unknown"
end;

define method print-protocol (frame :: <ethernet-frame>)
  next-method() | frame.type-code
end;

define method print-protocol (frame :: <header-frame>)
  print-protocol(frame.payload);
end;

define method print-protocol (frame :: <frame>)
  #f
end;
define method print-info (frame :: <frame-with-metadata>)
  summary(frame.real-frame.payload)
end;

define method print-number (frame :: <frame-with-metadata>)
  frame.number;
end;

define method print-time (gui :: <gui-sniffer-frame>, frame :: <frame-with-metadata>)
  let diff = frame.receive-time - gui.first-packet-arrived;
  let (days, hours, minutes, seconds, microseconds)
    = decode-duration(diff);
  let secs = (((days * 24 + hours) * 60) + minutes) * 60 + seconds;
  secs + as(<float>, microseconds) / 1000000
end;

define method apply-filter (frame :: <gui-sniffer-frame>)
  let filter-string = gadget-value(frame.filter-field);
  let old = frame.filter-expression;
  if (filter-string.size > 0)
    frame.filter-expression := parse-filter(filter-string);
    if (old ~= frame.filter-expression & every?(curry(\~=, filter-string), frame.filter-history))
      frame.filter-history := add!(frame.filter-history, filter-string);
      gadget-items(frame.filter-field) := frame.filter-history;
    end;
  else
    frame.filter-expression := #f
  end;
  if (old ~= frame.filter-expression)
    filter-packet-table(frame);
  end;
end;

define method filter-packet-table (frame :: <gui-sniffer-frame>)
  let shown-packets
    = if (frame.filter-expression)
        choose-by(rcurry(matches?, frame.filter-expression),
                  map(real-frame, frame.network-frames),
                  frame.network-frames)
      else
        frame.network-frames
      end;
  unless (shown-packets = gadget-items(frame.packet-table))
    gadget-items(frame.packet-table) := shown-packets;
    show-packet(frame);
  end;
end;

define method show-packet (frame :: <gui-sniffer-frame>)
  let packet = frame.packet-table.gadget-value;
  if (packet) packet := real-frame(packet) end;
  show-packet-tree(frame, packet);
  show-packet-hex-dump(frame, packet);
end;

define method show-packet-tree (frame :: <gui-sniffer-frame>, packet)
  frame.packet-tree-view.tree-control-roots
    := if (packet)
         frame-root-generator(packet);
       else
         #[]
       end;
end;

define method show-packet-hex-dump (frame :: <gui-sniffer-frame>, network-packet)
  frame.packet-hex-dump.gadget-value := get-hex-dump(network-packet);
end;

define function get-hex-dump (network-packet) => (string :: <string>)
  if (network-packet)
    //XXX: this should be easier!
    let out = make(<string-stream>, direction: #"output");
    block()
      hexdump(out, network-packet.packet); //XXX: once assemble-frame
                                           //on unparsed-container-frame works,
                                           //we can use assemble-frame here
      stream-contents(out);
    cleanup
      close(out)
    end
  else
    ""
  end;
end;
define method compute-absolute-offset (frame :: <ethernet-frame>)
 => (res :: <integer>)
  0
end;

define method find-frame-field (frame :: <container-frame>, search :: <container-frame>)
 => (res :: false-or(type-union(<frame-field>, <rep-frame-field>)))
  block(ret)
    for (ff in sorted-frame-fields(frame))
      if (ff.value == search)
        ret(ff)
      end;
      if (instance?(ff.value, <collection>))
        for (ele in ff.value, i from 0)
          if (ele == search)
            ret(ff.frame-field-list[i])
          end;
        end;
      end;
    end;
    #f;
  end;
end;

define method compute-absolute-offset (frame :: <container-frame>)
  if (frame.parent)
    let ff = find-frame-field(frame.parent, frame);
    compute-absolute-offset(ff);
  else
    0
  end;
end;
define method compute-absolute-offset (ff :: <rep-frame-field>)
 => (res :: <integer>)
  start-offset(ff) + compute-absolute-offset(ff.parent-frame-field);
end;
define method compute-absolute-offset (frame-field :: <frame-field>)
 => (res :: <integer>)
  start-offset(frame-field) + compute-absolute-offset(frame-field.frame)
end;

define method compute-length (frame :: <header-frame>) => (res :: <integer>)
  start-offset(sorted-frame-fields(frame).last)
end;

define method compute-length (frame :: <frame>) => (res :: <integer>)
  frame-size(frame)
end;

define method compute-length (frame-field :: <rep-frame-field>) => (res :: <integer>)
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
        format-out("looking in %s, offset %d\n", ff.field.field-name, offset - start-offset(ff));
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
        format-out("looking in %d, offset %d\n", i, offset - start);
        ret(find-frame-at-offset(ele, offset - start));
      end;
      start := start + frame-size(ele);
    end;
  end;
end;

define method find-frame-at-offset (frame :: <leaf-frame>, offset :: <integer>)
  frame;
end;

define method highlight-hex-dump (mframe :: <gui-sniffer-frame>)
  let packet = mframe.packet-table.gadget-value;
  let tree = mframe.packet-tree-view;
  let selected-packet = tree.gadget-items[tree.gadget-selection[0]];

  let start-highlight = compute-absolute-offset(selected-packet);
  let end-highlight = start-highlight + compute-length(selected-packet);

  let (start-line, start-rest) = floor/(byte-offset(start-highlight), 16);
  let (end-line, end-rest) = floor/(byte-offset(end-highlight + 7), 16);

  if (end-rest = 0)
    end-rest := 16;
    end-line := end-line - 1
  end;

  let hex-dump = split(get-hex-dump(packet.real-frame), '\n');
  
  let start-pos = 6 + start-rest * 3 + if (start-rest >= 8) 1 else 0 end;
  let end-pos = 6 + end-rest * 3 + if (end-rest > 8) 1 else 0 end;
  
  unless (start-line = end-line & start-pos = end-pos)
    hex-dump[start-line + 1][start-pos - 1] := '[';
    if (end-pos >= hex-dump[end-line + 1].size)
      hex-dump[end-line + 1] := add!(hex-dump[end-line + 1], ']');
    else
      hex-dump[end-line + 1][end-pos - 1] := ']';
    end;
  end;
  hex-dump := reduce1(method(a,b) concatenate(a, "\n", b) end, hex-dump);
  mframe.packet-hex-dump.gadget-value := hex-dump;
end;

define variable *count* :: <integer> = 0;
define method counter ()
  *count* := *count* + 1;
  *count*;
end;

define frame <gui-sniffer-frame> (<simple-frame>, <filter>)
  slot network-frames :: <stretchy-vector> = make(<stretchy-vector>);
  slot filter-expression = #f;
  slot ethernet-interface = #f;
  slot first-packet-arrived :: false-or(<date>) = #f;
  slot filter-history :: <list> = make(<list>);

  pane filter-field (frame)
    make(<combo-box>,
         label: "Filter expression",
         value-changed-callback: method(x) apply-filter(frame) end,
         activate-callback: method(x) apply-filter(frame) end,
         items: frame.filter-history);

  pane filter-pane (frame)
    horizontally()
      make(<label>, label: "Filter: ");
      frame.filter-field;
    end;

  pane packet-table (frame)
    make(<table-control>,
         headings: #("No", "Time", "Source", "Destination", "Protocol", "Info"),
         generators: list(print-number,
                          curry(print-time, frame),
                          print-source,
                          print-destination,
                          print-protocol,
                          print-info),
         items: #[],
         value-changed-callback: method(x) show-packet(frame) end);

  pane packet-tree-view (frame)
    make(<tree-control>,
         label-key: frame-print-label,
         children-generator: frame-children-generator,
         children-predicate: frame-children-predicate,
         value-changed-callback: method(x) highlight-hex-dump(frame) end);

  pane packet-hex-dump (frame)
    make(<text-editor>,
         read-only?: #t,
         tab-stop?: #t,
         lines: 20,
         columns: 100,
         scroll-bars: #"vertical",
         text-style: make(<text-style>, family: #"fix"));


  pane sniffer-status-bar (frame)
    make(<status-bar>, label: "GUI Sniffer");

  layout (frame) vertically()
                   frame.filter-pane;
                   frame.packet-table;
                   frame.packet-tree-view;
                   frame.packet-hex-dump;
                 end;

  command-table (frame) *gui-sniffer-command-table*;
  status-bar (frame) frame.sniffer-status-bar;
  keyword title: = "GUI Sniffer"
end;

define command-table *file-command-table* (*global-command-table*)
  menu-item "Open pcap file" = open-pcap-file;
  menu-item "Save to pcap file" = save-pcap-file;
end;

define command-table *interface-command-table* (*global-command-table*)
  menu-item "Open ethernet interface" = open-interface;
  menu-item "Stop capturing" = close-interface;
end;

define command-table *gui-sniffer-command-table* (*global-command-table*)
  menu-item "File" = *file-command-table*;
  menu-item "Interface" = *interface-command-table*;
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
  let (interface-name, promiscious?) = prompt-for-interface(owner: frame);
  if (interface-name)
    let interface = make(<ethernet-interface>,
                         name: interface-name,
                         promiscious?: promiscious?);
    connect(interface, frame);
    reinit-gui(frame);
    make(<thread>, function: curry(toplevel, interface));
    frame.ethernet-interface := interface;
    gadget-label(frame.sniffer-status-bar) := concatenate("Capturing ", interface-name);
  end;
end;

define method close-interface (frame :: <gui-sniffer-frame>)
  frame.ethernet-interface.running? := #f;
  gadget-label(frame.sniffer-status-bar) := "Stopped capturing";
  disconnect(frame.ethernet-interface, frame);
end;

define method prompt-for-interface
  (#key title = "Please specify interface", owner)
 => (interface-name :: false-or(<string>), promiscious? :: <boolean>)
  let devices = find-all-devices();
  let interfaces = make(<list-box>, items: devices);
  let promiscious? = make(<check-box>, items: #("promiscious"), selection: #[0]);
  let interface-selection-dialog
    = make(<dialog-frame>,
           title: title,
           owner: owner,
           layout: horizontally()
                     interfaces;
                     promiscious?
                   end);
  if (start-dialog(interface-selection-dialog))
    values(gadget-value(interfaces), size(gadget-value(promiscious?)) > 0)
  end;
end;

define method reinit-gui (frame :: <gui-sniffer-frame>)
  frame.first-packet-arrived := #f;
  *count* := 0;
  frame.network-frames := make(<stretchy-vector>);
  gadget-items(frame.packet-table) := #();
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
  add!(node.network-frames, frame-with-meta);
  if (~ node.filter-expression | matches?(frame, node.filter-expression))
    add-item(node.packet-table, make-item(node.packet-table, frame-with-meta))
  end;
end;

begin
  let gui-sniffer = make(<gui-sniffer-frame>);
  start-frame(gui-sniffer);
end;


