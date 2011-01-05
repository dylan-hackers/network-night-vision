module: simple-sniffer
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

begin
  let source = make(<ethernet-interface>, name: "Intel");
  connect(source, make(<summary-printer>, stream: *standard-output*));
  toplevel(source);
end;
