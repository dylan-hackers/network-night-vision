module: timer
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define class <recurrent-timer> (<object>)
  constant slot interval :: <integer>, required-init-keyword: interval:;
  constant slot real-event :: <function>, required-init-keyword: event:;
end;

define method initialize (timer :: <recurrent-timer>,
                          #next next-method,
                          #rest rest, #key, #all-keys)
  next-method();
  make(<timer>, in: timer.interval, event: curry(recurrent-event, timer));
end;

define method recurrent-event (t :: <recurrent-timer>) => (res)
  t.real-event();
  make(<timer>, in: t.interval, event: curry(recurrent-event, t));
end;

