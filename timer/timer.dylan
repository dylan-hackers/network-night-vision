module: timer
synopsis: 
author: 
copyright: 

define class <timer> (<priority-queueable-mixin>)
  constant slot timestamp :: <date>, required-init-keyword: timestamp:;
  constant slot event :: <function>, required-init-keyword: event:;
end;

define method make (timer == <timer>,
                    #next next-method,
                    #rest rest,
                    #key in,
                    #all-keys) => (timer :: <timer>)
  if (in)
    let (sec, microsec) = truncate(in);
    apply(next-method,
          timer,
          timestamp: current-date() + make(<day/time-duration>,
                                           seconds: sec,
                                           microseconds: round(microsec * 1000000)),
          rest)
  else
    apply(next-method, timer, rest)
  end;
end;

define method initialize (timer :: <timer>,
                          #next next-method,
                          #rest rest, #key,
                          #all-keys)
  next-method();
  with-lock($timer-manager.lock)
    add!($timer-manager.queue, timer);
    release($timer-manager.notification);
  end;
end;

define method cancel (timer :: <timer>)
  with-lock($timer-manager.lock)
    remove!($timer-manager.queue, timer)
  end;
end;


define class <timer-manager> (<object>)
  constant slot queue :: <priority-queue>
    = make(<priority-queue>,
           comparison-function: method (a, b)
                                  a.timestamp < b.timestamp
                                end);
  constant slot lock :: <lock> = make(<lock>);
  slot notification :: <notification>;
end;

define method initialize (timer-manager :: <timer-manager>,
                          #next next-method,
                          #rest rest, #key,
                          #all-keys)
  next-method();
  timer-manager.notification := make(<notification>, lock: timer-manager.lock);
  let worker = make(<thread>,
                    function: curry(worker-function, timer-manager));
end;

define constant $timer-manager = make(<timer-manager>);

define function decode-seconds (day/time-duration :: <day/time-duration>)
 => (seconds :: <real>)
  let (days, hours, minutes, seconds, microseconds)
   = decode-duration(day/time-duration);
  minutes * 60 + seconds + microseconds / 1000000.0;
end;

define function worker-function (timer-manager :: <timer-manager>)
  wait-for(timer-manager.lock);
  while (#t)
    let time = current-date();
    let timeout = if (timer-manager.queue.size > 0)
                    decode-seconds(timer-manager.queue.first.timestamp - time);
                  end;
    if (timeout & timeout < 0)
      let timer = pop(timer-manager.queue);
      release(timer-manager.lock);
      timer.event();
      wait-for(timer-manager.lock);
    else
      wait-for(timer-manager.notification, timeout: timeout);
    end;
  end;
  release(timer-manager.lock);
end;
