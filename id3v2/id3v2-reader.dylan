module:         id3v2
author: mb, Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 mb, Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define class <id3v2-reader> (<single-push-output-node>)
  slot file-stream :: <stream>, required-init-keyword: stream:;
end;

define method toplevel (reader :: <id3v2-reader>)
  //let file = as(<byte-vector>, stream-contents(reader.file-stream));
  let tag-data = read-to(reader.file-stream, as(<character>, #xff), test: \==);
  let id3v2-container = parse-frame(<id3v2-tag>, tag-data);
  format-out("%s\n", as(<string>, id3v2-container));
  format-out("repeated fields: %d\n", id3v2-container.id3v2-frame.size);
end;
