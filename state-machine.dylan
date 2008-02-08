Module:    state-machine
Synopsis:  State Machine definition macros
Author:    Hannes Mehnert
Copyright: (C) 2007,  All rights reversed.


define open abstract class <protocol-state> (<object>) end;

define open abstract class <protocol-state-encapsulation> (<object>)
  constant slot lock :: <simple-lock> = make(<simple-lock>);
  slot state :: <protocol-state>;
  slot debugging? :: <boolean> = #f, init-keyword: debugging?:;
end;

define macro singleton-class-definer
  { define singleton-class ?:name (?superclass:name) ?slots:* end }
 =>
  { define class ?name (?superclass) ?slots end;
    define variable "*" ## ?name ## "-instance*" :: false-or(?name) = #f;
    define method make (class == ?name,
                        #next next-method, #rest rest, #key, #all-keys)
     => (instance :: ?name);
      "*" ## ?name ## "-instance*"
        | ("*" ## ?name ## "-instance*" := next-method())
    end;
  }
end;

define macro states
  { states(?state:name; ?superstate:name) }
    => { define singleton-class ?state (?superstate) end }
  { states(?state:name, ?rest:*; ?superstate:name) }
    =>
    { define singleton-class ?state (?superstate) end;
      states(?rest; ?superstate) }
end;

define open generic next-state (state :: <protocol-state>, event :: <symbol>)
 => (res :: <protocol-state>);

define method next-state (state :: <protocol-state>, event :: <symbol>)
 => (res :: <protocol-state>)
  state
end;

define method process-event (dingens :: <protocol-state-encapsulation>, event :: <symbol>)
  with-lock (dingens.lock)
    let old-state = dingens.state;
    let new-state = next-state(old-state, event);
    if (dingens.debugging?)
      format-out("Event %= triggers state transition %= => %=\n", event, old-state, new-state);
    end;
    dingens.state := new-state;
    state-transition(dingens, old-state, event, new-state);
  end;
end;

define open generic state-transition (dingens :: <protocol-state-encapsulation>,
                                      old-state :: <protocol-state>,
                                      event,
                                      new-state :: <protocol-state>) => ();

define method state-transition (dingens :: <protocol-state-encapsulation>,
                                old-state :: <protocol-state>,
                                event,
                                new-state :: <protocol-state>) => ()
  ignore(dingens, old-state, event, new-state)
end;  

define macro state-transition-rule-definer
  { define state-transition-rule ?old-state:name ?event:expression ?new-state:name end }
    => { define method next-state (state :: ?old-state, event == ?event)
          => (result-state :: ?new-state)
           make(?new-state)
         end }
end;
