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
  instance?(frame-field.value, <container-frame>)
    | (instance?(frame-field.field, <repeated-field>) & frame-field.value.size > 0)
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
  if (instance?(frame-field.field, <repeated-field>))
    frame-field.value
  elseif (instance?(frame-field.value, <container-frame>))
    sorted-frame-fields(frame-field.value)
  else
    error("huh?")
  end
end;

define method frame-root-generator (frame :: <header-frame>)
  add!(frame-root-generator(payload(frame)), frame);
end;

define method frame-root-generator (frame :: <frame>)
  list(frame);
end;
define method frame-print-label (frame-field :: <frame-field>)
  if (~ frame-children-predicate(frame-field))
    format-to-string("%s: %=", frame-field.field.field-name, frame-field.value)
  elseif (instance?(frame-field.value, <container-frame>))
    format-to-string("%s: %s %s",
                     frame-field.field.field-name, 
                     frame-field.value.frame-name,
                     frame-field.value.summary)
  elseif (instance?(frame-field.field, <repeated-field>))
    format-to-string("%s: %= %s",
                     frame-field.field.field-name,
                     frame-field.value.size,
                     frame-field.field.type)
  else
    format-to-string("%s", frame-field.field.field-name)
  end
end;

define method frame-print-label (frame :: <container-frame>)
  format-to-string("%s %s", frame.frame-name, frame.summary);
end;

define method frame-print-label (frame :: <leaf-frame>)
  format-to-string("%=", frame);
end;

define method print-source (frame :: <ethernet-frame>)
  as(<string>, frame.source-address)
end;

define method print-destination (frame :: <ethernet-frame>)
  as(<string>, frame.destination-address)
end;

define method print-protocol (frame :: <ethernet-frame>)
  frame.type-code
end;

define method print-info (frame :: <ethernet-frame>)
  summary(frame.payload)
end;

define method apply-filter (frame :: <gui-sniffer-frame>)
  let filter-string = gadget-value(frame.filter-field);
  let old = frame.filter-expression;
  if (filter-string.size > 0)
    frame.filter-expression := parse-filter(filter-string)
  else
    frame.filter-expression := #f
  end;
  if (old ~= frame.filter-expression)
    refresh-packet-table(frame);
  end;
end;

define method show-packet (frame :: <gui-sniffer-frame>)
  let packet = frame.packet-table.gadget-value;
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
  //XXX: this should be easier!
  frame.packet-hex-dump.gadget-value
    := if (network-packet)
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

define variable *count* :: <integer> = 0;
define method counter (frame :: <object>)
  *count* := *count* + 1;
  *count*;
end;

define frame <gui-sniffer-frame> (<simple-frame>, <filter>)
  slot network-frames = make(<stretchy-vector>);
  slot filter-expression = #f;
  slot ethernet-interface = #f;

  pane filter-field (frame)
    make(<text-field>,
         label: "Filter expression",
         activate-callback: method(x) apply-filter(frame) end);

  pane filter-pane (frame)
    horizontally()
      make(<label>, label: "Filter: ");
      frame.filter-field;
    end;

  pane packet-table (frame)
    make(<table-control>,
         headings: #("No", "Source", "Destination", "Protocol", "Info"),
         generators: list(counter, print-source, print-destination, print-protocol, print-info),
         items: #[],
         value-changed-callback: method(x) show-packet(frame) end);

  pane packet-tree-view (frame)
    make(<tree-control>,
         label-key: frame-print-label,
         children-generator: frame-children-generator,
         children-predicate: frame-children-predicate);

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
    frame.network-frames := make(<stretchy-vector>);
    refresh-packet-table(frame);
    let file-stream = make(<file-stream>, locator: file, direction: #"input");
    let pcap-reader = make(<pcap-file-reader>, stream: file-stream);
    connect(pcap-reader, frame);
    toplevel(pcap-reader);
    gadget-label(frame.sniffer-status-bar) := concatenate("Opened ", file);
    close(file-stream);
    refresh-packet-table(frame);
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
    do(curry(push-data, frame.the-output), frame.network-frames);
    //XXX: disconnect in flow graph, but disconnect is NYI
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
    frame.network-frames := make(<stretchy-vector>);
    refresh-packet-table(frame);
    make(<thread>, function: curry(toplevel, interface));
    frame.ethernet-interface := interface;
    gadget-label(frame.sniffer-status-bar) := concatenate("Capturing ", interface-name);
  end;
end;

define method close-interface (frame :: <gui-sniffer-frame>)
  frame.ethernet-interface.running? := #f;
  gadget-label(frame.sniffer-status-bar) := "Stopped capturing";
  //XXX: disconnect in flow graph, but disconnect is NYI
end;

define method prompt-for-interface
  (#key title = "Please specify interface", owner)
 => (interface-name :: false-or(<string>), promiscious? :: <boolean>)
  let interface-text = make(<text-field>,
                            label: "Interface:",
                            activate-callback: exit-dialog);
  let promiscious? = make(<check-box>, items: #("promiscious"), selection: #[0]);
  let interface-selection-dialog
    = make(<dialog-frame>,
           title: title,
           owner: owner,
           layout: horizontally()
                     interface-text;
                     promiscious?
                   end,
           input-focus: interface-text);
  if (start-dialog(interface-selection-dialog))
    values(gadget-value(interface-text), size(gadget-value(promiscious?)) > 0)
  end;
end;

define method refresh-packet-table (frame :: <gui-sniffer-frame>)
  let shown-packets = if (frame.filter-expression)
                        choose(rcurry(matches?, frame.filter-expression),
                               frame.network-frames)
                      else
                        frame.network-frames
                      end;
  *count* := 0;
  if (shown-packets = gadget-items(frame.packet-table))
    update-gadget(frame.packet-table)
  else
    gadget-items(frame.packet-table) := shown-packets;
    show-packet(frame);
  end;
end;

define method push-data-aux (input :: <push-input>,
                             node :: <gui-sniffer-frame>,
                             frame :: <frame>)
  add!(node.network-frames, frame);
  if (~ node.filter-expression | matches?(frame, node.filter-expression))
    add-item(node.packet-table, make-item(node.packet-table, frame))
  end;
end;
begin
  let gui-sniffer = make(<gui-sniffer-frame>);
  start-frame(gui-sniffer);
end;


