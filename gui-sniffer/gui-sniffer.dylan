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
  instance?(frame-field.frame, <container-frame>)
    | (instance?(frame-field.field, <repeated-field>) & frame-field.frame.size > 0)
end;

define method frame-children-generator (collection :: <collection>)
  collection
end;

define method frame-children-generator (a-frame :: <container-frame>)
  sorted-frame-fields(a-frame)
end;

define method frame-children-generator (frame-field :: <frame-field>)
  if (instance?(frame-field.field, <repeated-field>))
    frame-field.frame
  elseif (instance?(frame-field.frame, <container-frame>))
    sorted-frame-fields(frame-field.frame)
  else
    error("huh?")
  end
end;

define method frame-print-label (frame-field :: <frame-field>)
  if (~ frame-children-predicate(frame-field))
    format-to-string("%s: %=", frame-field.field.field-name, frame-field.frame)
  elseif (instance?(frame-field.frame, <container-frame>))
    format-to-string("%s: %s %s",
                     frame-field.field.field-name, 
                     frame-field.frame.frame-name,
                     frame-field.frame.summary)
  elseif (instance?(frame-field.field, <repeated-field>))
    format-to-string("%s: %= %s",
                     frame-field.field.field-name,
                     frame-field.frame.size,
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

define variable *frame* = #f;

begin
  let file = as(<byte-vector>, 
                with-open-file (stream = "c:\\cap.pcap",
                                direction: #"input")
                  stream-contents(stream);
                end);
  let pcap-file = make(unparsed-class(<pcap-file>),
                       packet: file);
  *frame* := map(payload, packets(pcap-file));
  contain(frame-viewer(*frame*));
end;


