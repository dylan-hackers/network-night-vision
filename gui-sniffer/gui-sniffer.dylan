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

define method frame-children-generator (frame-field :: <frame-field>)
  if (instance?(frame-field.field, <repeated-field>))
    frame-field.value
  elseif (instance?(frame-field.value, <container-frame>))
    sorted-frame-fields(frame-field.value)
  else
    error("huh?")
  end
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

define method frame-viewer(frame :: <frame>)
  make(<tree-control>, 
       roots: vector(frame),
       label-key: frame-print-label,
       children-generator: frame-children-generator,
       children-predicate: frame-children-predicate)
end;

define method frame-viewer(frames :: <collection>)
  make(<tree-control>, 
       roots: frames,
       label-key: frame-print-label,
       children-generator: frame-children-generator,
       children-predicate: frame-children-predicate)
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

define method show-packet-tree (frame :: <gui-sniffer-frame>)
  let packet = frame.packet-table.gadget-value;
  frame.packet-tree-view.tree-control-roots
    := if (packet)
         frame-children-generator(packet);
       else
         #[]
       end;
end;
define variable *count* :: <integer> = 0;
define method counter (frame :: <object>)
  *count* := *count* + 1;
  *count*;
end;
define frame <gui-sniffer-frame> (<simple-frame>)
  slot network-frames = make(<stretchy-vector>);
  slot filter-expression = #f;
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
         value-changed-callback: method(x) show-packet-tree(frame) end);

  pane packet-tree-view (frame)
    make(<tree-control>,
         label-key: frame-print-label,
         children-generator: frame-children-generator,
         children-predicate: frame-children-predicate);

  layout (frame) vertically()
                   frame.filter-pane;
                   frame.packet-table;
                   frame.packet-tree-view;
                 end;

  command-table (frame) *gui-sniffer-command-table*;
  keyword title: = "GUI Sniffer"
end;

define command-table *file-command-table* (*global-command-table*)
  menu-item "Open pcap file" = open-pcap-file;
end;

define command-table *gui-sniffer-command-table* (*global-command-table*)
  menu-item "File" = *file-command-table*;
end;

define method open-pcap-file (frame :: <gui-sniffer-frame>)
  let file = choose-file(frame: frame, direction: #"input");
  if (file)
    let packets = load-pcap-file(file);
    if (packets)
      frame.network-frames := packets;
      refresh-packet-table(frame);
    else
      notify-user(format-to-string("Failed to open file %s", file), owner: frame)
    end;
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
  end;
  show-packet-tree(frame);
end;
define method load-pcap-file (file :: <string>) => (res :: false-or(<collection>))
  let file-content
    = as(<byte-vector>, 
         with-open-file (stream = file,
                         direction: #"input")
           stream-contents(stream);
         end);
  let pcap-file = make(unparsed-class(<pcap-file>),
                       packet: file-content);
  //now check for real pcap-header... and return worst case #f
  map(payload, packets(pcap-file));
end;
begin
  let gui-sniffer-frame = make(<gui-sniffer-frame>);
  start-frame(gui-sniffer-frame); 
end;


