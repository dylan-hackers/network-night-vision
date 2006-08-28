module: id3v2-test
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define function main()
  let input-stream = make(<file-stream>, locator: "test.mp3", direction: #"input");
  let id3v2-reader = make(<id3v2-reader>, stream: input-stream);
  toplevel(id3v2-reader);
end;

main();

