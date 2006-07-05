module: timer

define method main ()
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

define method print-date ()
  let date = current-date();
  format-out("%s\n", as-iso8601-string(date));
end;

begin
 //main();
end;
