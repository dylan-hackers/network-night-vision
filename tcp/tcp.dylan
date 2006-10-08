Module:    tcp
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define open class <tcp-dingens> (<object>)
  constant slot lock :: <simple-lock> = make(<simple-lock>);
  slot state :: <tcp-state> = make(<closed>);
end;

define abstract class <tcp-state> (<object>)
end;

define macro singleton-class-definer
  { define singleton-class ?:name (?superclass:name) ?slots:* end }
 =>
  { define class ?name (?superclass) ?slots end;
    define variable "*" ## ?name ## "-instance*" :: false-or(?name) = #f;
    define method make(class == ?name, #next next-method, #rest rest, #key, #all-keys)
     => (instance :: ?name);
      "*" ## ?name ## "-instance*" | ("*" ## ?name ## "-instance*" := next-method())
    end;
  }
end;

define singleton-class <closed> (<tcp-state>)
end;

define singleton-class <listen> (<tcp-state>)
end;

define singleton-class <syn-sent> (<tcp-state>)
end;

define singleton-class <syn-received> (<tcp-state>)
end;

define singleton-class <established> (<tcp-state>)
end;

define singleton-class <fin-wait1> (<tcp-state>)
end;

define singleton-class <fin-wait2> (<tcp-state>)
end;

define singleton-class <closing> (<tcp-state>)
end;

define singleton-class <time-wait> (<tcp-state>)
end;

define singleton-class <close-wait> (<tcp-state>)
end;

define singleton-class <last-ack> (<tcp-state>)
end;

define constant <tcp-events> = one-of(#"passive-open", #"active-open", #"close", #"syn-received", #"syn-ack-received",
                                      #"rst-received", #"fin-received", #"ack-received", #"fin-ack-received",
                                      #"2msl-timeout", #"last-ack-received");

define generic next-state (state :: <tcp-state>, event :: <tcp-events>) => (res :: <tcp-state>);

define method next-state (state :: <tcp-state>, event :: <tcp-events>) => (res :: <tcp-state>)
  state
end;

define method next-state (state :: <tcp-state>, event == #"rst-received") => (res :: <tcp-state>)
  make(<closed>)
end;

define method next-state (state :: <closed>, event == #"active-open") => (res :: <tcp-state>)
  make(<syn-sent>)  
end;
define method next-state (state :: <closed>, event == #"passive-open") => (new-state :: <tcp-state>);
  make(<listen>)
end;

define method next-state (state :: <listen>, event == #"syn-received") => (new-state :: <tcp-state>);
  make(<syn-received>)
end;

define method next-state (state :: <syn-sent>, event == #"close") => (new-state :: <tcp-state>);
  make(<closed>)
end;

define method next-state (state :: <syn-sent>, event == #"syn-received") => (new-state :: <tcp-state>);
  make(<syn-received>)
end;

define method next-state (state :: <syn-sent>, event == #"syn-ack-received") => (new-state :: <tcp-state>);
  make(<established>)
end;

define method next-state (old-state :: <syn-received>, event == #"rst-received") => (new-state :: <tcp-state>);
  make(<listen>)
end;

define method next-state (old-state :: <syn-received>, event == #"last-ack-received") => (new-state :: <tcp-state>);
  make(<established>)
end;

define method next-state (old-state :: <syn-received>, event == #"close") => (new-state :: <tcp-state>);
  make(<fin-wait1>)
end;

define method next-state (old-state :: <established>, event == #"close") => (new-state :: <tcp-state>);
  make(<fin-wait1>)
end;

define method next-state (old-state :: <established>, event == #"fin-received") => (new-state :: <tcp-state>);
  make(<close-wait>)
end;

define method next-state (old-state :: <established>, event == #"fin-ack-received") => (new-state :: <tcp-state>);
  make(<close-wait>)
end;

define method next-state (old-state :: <close-wait>, event == #"close") => (new-state :: <tcp-state>);
  make(<last-ack>)
end;

define method next-state (old-state :: <last-ack>, event == #"last-ack-received") => (new-state :: <tcp-state>);
  make(<closed>)
end;

define method next-state (old-state :: <fin-wait1>, event == #"fin-received") => (new-state :: <tcp-state>);
  make(<closing>)
end;

define method next-state (old-state :: <fin-wait1>, event == #"last-ack-received") => (new-state :: <tcp-state>);
  make(<fin-wait2>)
end;

define method next-state (old-state :: <fin-wait1>, event == #"fin-ack-received") => (new-state :: <tcp-state>);
  make(<time-wait>)
end;

define method next-state (old-state :: <fin-wait2>, event == #"fin-received") => (new-state :: <tcp-state>);
  make(<time-wait>)
end;

define method next-state (old-state :: <fin-wait2>, event == #"fin-ack-received") => (new-state :: <tcp-state>);
  make(<time-wait>)
end;

define method next-state (old-state :: <closing>, event == #"last-ack-received") => (new-state :: <tcp-state>);
  make(<time-wait>)
end;

define method next-state (state :: <time-wait>, event == #"2msl-timeout") => (new-state :: <tcp-state>)
  make(<closed>)
end;

define method process-event (dingens :: <tcp-dingens>, event :: <tcp-events>)
  let old-state = dingens.state;
  let new-state = next-state(old-state, event);
  format-out("State transition %= => %=\n", old-state, new-state);
  dingens.state := new-state;
  state-transition(dingens, old-state, new-state);
end;

define open generic state-transition (dingens :: <tcp-dingens>, old-state :: <tcp-state>, new-state :: <tcp-state>) => ();

define method state-transition (dingens :: <tcp-dingens>, old-state :: <tcp-state>, new-state :: <tcp-state>) => ()
  ignore(dingens, old-state, new-state)
end;  

/*
begin
  let tcp = make(<tcp-dingens>);
  while(#t)
    let line = read-line(*standard-input*);
    let event = 
      select(line by \=)
        "po" => passive-open;
        "ao" => active-open;
        "c" => close;
        "s" => syn-received;
        "sa" => syn-ack-received;
        "r" => rst-received;
        "f" => fin-received;
        "a" => ack-received;
        "fa" => fin-ack-received;
      end;
    event(tcp)
  end
end; */
/*
closed; application: open; syn-sent; frame: syn
listen; frame: syn; syn-received; frame: syn & ack
syn-received; frame: ack; established;
established; frame: fin; close-wait; frame: ack
syn-sent; timeout: 300; closed;
syn-sent; application: close; closed;
*/



