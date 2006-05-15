module: timer

define method main ()
  let date = current-date();
  let timer1 = make(<timer>,
                    timestamp: date + make(<day/time-duration>, seconds: 1),
                    event: print-date);
  let timer3 = make(<timer>,
                    timestamp: date + make(<day/time-duration>, seconds: 3),
                    event: print-date);
  let timer10 = make(<timer>,
                     timestamp: date + make(<day/time-duration>, seconds: 10),
                     event: print-date);
end;

define method print-date ()
  let date = current-date();
  format-out("%s\n", as-iso8601-string(date));
end;

begin
  main();
  sleep(23.5);
end;