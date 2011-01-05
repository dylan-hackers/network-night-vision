module: id3v2-test
author: mb, Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 mb, Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in the parent directory

define function main()
  let input-stream = make(<file-stream>, locator: "test.mp3", direction: #"input");
  let id3v2-reader = make(<id3v2-reader>, stream: input-stream);
  toplevel(id3v2-reader);
end;

main();

