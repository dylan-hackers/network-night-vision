module:         id3v2
Author:         Andreas Bogk, Hannes Mehnert, mb
Copyright:      (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define class <id3v2-reader> (<single-push-output-node>)
  slot file-stream :: <stream>, required-init-keyword: stream:;
end;

define method toplevel (reader :: <id3v2-reader>)
  //let file = as(<byte-vector>, stream-contents(reader.file-stream));
  let tag-data = read-to(reader.file-stream, as(<character>, #xff), test: \==);
  let id3v2-container = make(unparsed-class(<id3v2-tag>), packet: as(<byte-vector>, tag-data));
  format-out("%s\n", as(<string>, id3v2-container));
  format-out("repeated fields: %d\n", id3v2-container.id3v2-frame.size);
end;