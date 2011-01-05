module: timer
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define method main ()
  let timer23 = make(<recurrent-timer>, interval: 2, event: print-foo);
  let timer1 = make(<timer>, in: 1, event: print-date);
  let timer3 = make(<timer>, in: 3, event: print-date);
  let timer8 = make(<timer>, in: 8, event: print-date);
  let timer10 = make(<timer>, in: 10, event: print-date);
  let timer11 = make(<timer>, in: 11.8, event: print-date);
  let timer12 = make(<timer>, in: 12, event: print-date);
  sleep(11);
  cancel(timer11);
  sleep(3);
end;

define method print-foo ()
  format-out("FOO\n");
end;
define method print-date ()
  let date = current-date();
  format-out("%s\n", as-iso8601-string(date));
end;

begin
 //main();
end;
