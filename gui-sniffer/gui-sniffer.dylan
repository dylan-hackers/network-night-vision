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
  let out = make(<string-stream>, direction: #"output");
  let hex = block()
              hexdump(out, raw-frame.data);
              stream-contents(out);
            cleanup
              close(out)
            end;
  let lines = split(hex, '\n');
  if (lines[0] = "")
    lines := copy-sequence(lines, start: 1)
  end;
  if (lines[lines.size - 1] = "")
    lines := copy-sequence(lines, end: lines.size - 1)
  end;

  let start :: <integer> = 0;
  let length :: <integer> = 16 * 8;
  map(method(x)
        let rff = make(<raw-frame-element>,
                       start: start,
                       length: length,
                       end: start + length,
                       raw-frame: raw-frame,
                       value: x);
        start := start + length;
        rff;
      end, lines)
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

define method find-protocol-name (frame :: type-union(<raw-frame>, <container-frame>))
  let res = payload-type(frame);
  if (res = <raw-frame>)
    #f
  else
    res;
  end;
end;

define method payload-type (frame :: type-union(<raw-frame>, <container-frame>)) => (res)
  #f
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

define method print-time (gui :: <gui-sniffer-frame>, frame :: <frame-with-metadata>)
  let diff = frame.receive-time - gui.first-packet-arrived;
  let (days, hours, minutes, seconds, microseconds)
    = decode-duration(diff);
  let secs = (((days * 24 + hours) * 60) + minutes) * 60 + seconds;
  concatenate(integer-to-string(secs), ".", integer-to-string(truncate/(microseconds, 1000), size: 3));
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
    gadget-items(frame.packet-table) := #();
    do(method(x)
         add-item(frame.packet-table, make-item(frame.packet-table, x))
       end, shown-packets);
    show-packet(frame);
  end;
end;

define method show-packet (frame :: <gui-sniffer-frame>)
  let current-packet = frame.packet-table.gadget-value;
  if (current-packet) current-packet := real-frame(current-packet) end;
  show-packet-tree(frame, current-packet);
  current-packet & show-hexdump(frame, current-packet.packet);
  redisplay-window(frame.packet-hex-dump);
//  note-gadget-text-changed(window);
//  note-gadget-value-changed(window);
end;

define method show-packet-tree (frame :: <gui-sniffer-frame>, packet)
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

define method compute-absolute-offset (frame :: type-union(<container-frame>, <raw-frame>), relative-to)
  format-out("%= %=\n", frame, relative-to);
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

define method highlight-hex-dump (mframe :: <gui-sniffer-frame>)
  let packet = mframe.packet-table.gadget-value;
  let tree = mframe.packet-tree-view;
  let selected-packet = tree.gadget-items[tree.gadget-selection[0]];

  let start-highlight = compute-absolute-offset(selected-packet, packet.real-frame);
  let end-highlight = start-highlight + compute-length(selected-packet);

  set-highlight(mframe, start-highlight, end-highlight);
  redisplay-window(mframe.packet-hex-dump);

end;

define variable *count* :: <integer> = 0;
define method counter ()
  *count* := *count* + 1;
  *count*;
end;

define constant $text-style = make(<text-style>, family: #"fix", size: 8);

define frame <gui-sniffer-frame> (<simple-frame>, deuce/<basic-editor-frame>, <filter>)
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
         generators: list(print-number,
                          curry(print-time, frame),
                          print-source,
                          print-destination,
                          print-protocol,
                          print-info),
         widths: #[30, 60, 150, 150, 100, 500],
         items: #[],
         text-style: $text-style,
         popup-menu-callback: display-popup-menu,
         value-changed-callback: method(x) show-packet(frame) end);

  pane packet-tree-view (frame)
    make(<tree-control>,
         label-key: frame-print-label,
         children-generator: frame-children-generator,
         children-predicate: frame-children-predicate,
         text-style: $text-style,
         value-changed-callback: method(x) highlight-hex-dump(frame) end);

  pane packet-hex-dump (frame)
    make(<deuce-pane>,
         frame: frame,
         read-only?: #t,
         tab-stop?: #t,
         lines: 20,
         columns: 100,
         scroll-bars: #"vertical",
         text-style: $text-style);


  pane sniffer-status-bar (frame)
    make(<status-bar>, label: "GUI Sniffer");

  pane open-button (frame)
    make(<push-button>, label: $icons["open"],
         activate-callback: method(x) open-pcap-file(frame) end);
  pane save-button (frame)
    make(<push-button>, label: $icons["save"],
         activate-callback: method(x) save-pcap-file(frame) end);
  pane play-button (frame)
    make(<push-button>, label: $icons["play"],
         activate-callback: method(x) open-interface(frame) end);
  pane stop-button (frame)
    make(<push-button>, label: $icons["stop"],
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
                                         end));
                 end;

  tool-bar (frame) frame.sniffer-tool-bar;
  command-table (frame) *gui-sniffer-command-table*;
  status-bar (frame) frame.sniffer-status-bar;
  keyword title: = "GUI Sniffer"
end;

define command-table *file-command-table* (*global-command-table*)
  menu-item "Open pcap file..." = open-pcap-file;
  menu-item "Save to pcap file..." = save-pcap-file;
end;

define command-table *interface-command-table* (*global-command-table*)
  menu-item "Start..." = open-interface;
  menu-item "Stop" = close-interface;
end;

define command-table *gui-sniffer-command-table* (*global-command-table*)
  menu-item "File" = *file-command-table*;
  menu-item "Capture" = *interface-command-table*;
end;

define command-table *popup-menu-command-table* (*global-command-table*)
  menu-item "Follow TCP Stream" = follow-tcp-stream;
end;

define method display-popup-menu (sheet, object, #key x, y)
  let frame = sheet.sheet-frame;
  let menu = make-menu-from-command-table-menu
               (command-table-menu(*popup-menu-command-table*),
                frame, frame-manager(frame),
                command-table: *popup-menu-command-table*,
                owner: frame);
  display-menu(menu);
end;

define method follow-tcp-stream (frame :: <gui-sniffer-frame>)
  //
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
    let interface = make(<ethernet-interface>,
                         name: interface-name,
                         promiscuous?: promiscuous?);
    connect(interface, frame);
    reinit-gui(frame);
    make(<thread>, function: curry(toplevel, interface));
    frame.ethernet-interface := interface;
    gadget-label(frame.sniffer-status-bar) := concatenate("Capturing ", interface-name);
    command-enabled?(open-pcap-file, frame) := #f;
    gadget-enabled?(frame.open-button) := #f;
    command-enabled?(open-interface, frame) := #f;
    gadget-enabled?(frame.play-button) := #f;
    command-enabled?(close-interface, frame) := #t;
    gadget-enabled?(frame.stop-button) := #t;
  end;
end;

define method close-interface (frame :: <gui-sniffer-frame>)
  frame.ethernet-interface.running? := #f;
  gadget-label(frame.sniffer-status-bar) := "Stopped capturing";
  disconnect(frame.ethernet-interface, frame);
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
  let interfaces = make(<list-box>, items: devices);
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

define constant $icons = make(<string-table>);

define function initialize-icons ()
  local method doit (name)
    $icons[as-lowercase(name)]
      := read-image-as(<win32-icon>, as(<byte-string>, name), #"icon", width: 16, height: 16);
  end;
  doit("PLAY");
  doit("OPEN");
  doit("SAVE");
  doit("STOP");
end;

begin
  initialize-icons();
  let gui-sniffer = make(<gui-sniffer-frame>);
  set-frame-size(gui-sniffer, 800, 600);
  deuce/frame-window(gui-sniffer) := gui-sniffer.packet-hex-dump;
  deuce/*editor-frame* := gui-sniffer;
  deuce/*buffer* := deuce/make-initial-buffer();
  deuce/select-buffer(frame-window(gui-sniffer), deuce/*buffer*);
  command-enabled?(close-interface, gui-sniffer) := #f;
  gadget-enabled?(gui-sniffer.stop-button) := #f;
  start-frame(gui-sniffer);
end;



