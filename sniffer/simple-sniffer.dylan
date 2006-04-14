module: simple-sniffer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

begin
  let source = make(<ethernet-interface>, name: "eth0");
  connect(source, make(<summary-printer>, stream: *standard-output*));
  toplevel(source);
end;