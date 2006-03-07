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
  #t
end;

define method frame-children-predicate (object :: <object>)
  #f
end;

define method frame-children-predicate (frame-field :: <frame-field>)
  instance?(frame-field.frame, <container-frame>)
    | instance?(frame-field.field, <repeated-field>)
end;

define method frame-children-generator (collection :: <collection>)
  collection
end;

define method frame-children-generator (a-frame :: <container-frame>)
  a-frame.concrete-frame-fields
end;

define method frame-children-generator (frame-field :: <frame-field>)
  if (instance?(frame-field.field, <repeated-field>))
    frame-field.frame
  elseif (instance?(frame-field.frame, <container-frame>))
    frame-field.frame.concrete-frame-fields
  else
    error("huh?")
  end
end;

define method frame-print-label (frame-field :: <frame-field>)
  if (~ frame-children-predicate(frame-field))
    format-to-string("%s: %=", frame-field.field.name, frame-field.frame)
  elseif (instance?(frame-field.frame, <container-frame>))
    format-to-string("%s: %s",
                     frame-field.field.name, 
                     frame-field.frame.name)
  elseif (instance?(frame-field.field, <repeated-field>))
    format-to-string("%s: %= %s",
                     frame-field.field.name,
                     frame-field.frame.size,
                     frame-field.field.type)
  else
    format-to-string("%s", frame-field.field.name)
  end
end;

define method frame-print-label (frame :: <container-frame>)
  format-to-string("%s", frame.name);
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

define variable *frame* = #f;

begin
  let file = as(<byte-vector>, 
                with-open-file (stream = "c:\\dylan\\capture.pcap",
                                direction: #"input")
                  stream-contents(stream);
                end);
  *frame* := parse-frame(<pcap-file>, file);
  contain(frame-viewer(*frame*));
end;


