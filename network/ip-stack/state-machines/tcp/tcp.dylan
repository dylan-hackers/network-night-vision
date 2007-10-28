Module:    tcp-state-machine
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define open class <tcp-dingens> (<protocol-state-encapsulation>)
  inherited slot state = make(<closed>);
end;

define abstract class <tcp-state> (<protocol-state>) end;

states(<closed>, <listen>, <syn-sent>, <syn-received>,
       <established>, <fin-wait1>, <fin-wait2>, <closing>,
       <time-wait>, <close-wait>, <last-ack>; <tcp-state>);

define constant <tcp-events>
  = one-of(#"passive-open", #"active-open", #"close", #"syn-received",
           #"syn-ack-received", #"rst-received", #"fin-received",
           #"ack-received", #"fin-ack-received", #"2msl-timeout",
           #"last-ack-received");


define state-transition-rule <tcp-state> #"rst-received" <closed> end;
define state-transition-rule <closed> #"active-open" <syn-sent> end;
define state-transition-rule <closed> #"passive-open" <listen> end;
define state-transition-rule <listen> #"syn-received" <syn-received> end;
define state-transition-rule <syn-sent> #"close" <closed> end;
define state-transition-rule <syn-sent> #"syn-received" <syn-received> end;
define state-transition-rule <syn-sent> #"syn-ack-received" <established> end;
define state-transition-rule <syn-received> #"rst-received" <listen> end;
define state-transition-rule <syn-received> #"last-ack-received" <established> end;
define state-transition-rule <syn-received> #"close" <fin-wait1> end;
define state-transition-rule <established> #"close" <fin-wait1> end;
define state-transition-rule <established> #"fin-received" <close-wait> end;
define state-transition-rule <established> #"fin-ack-received" <close-wait> end;
define state-transition-rule <close-wait> #"close" <last-ack> end;
define state-transition-rule <last-ack> #"last-ack-received" <closed> end;
define state-transition-rule <fin-wait1> #"fin-received" <closing> end;
define state-transition-rule <fin-wait1> #"last-ack-received" <fin-wait2> end;
define state-transition-rule <fin-wait1> #"fin-ack-received" <time-wait> end;
define state-transition-rule <fin-wait2> #"fin-received" <time-wait> end;
define state-transition-rule <fin-wait2> #"fin-ack-received" <time-wait> end;
define state-transition-rule <closing> #"last-ack-received" <time-wait> end;
define state-transition-rule <time-wait> #"2msl-timeout" <closed> end;


/*
begin
  let tcp = make(<tcp-dingens>);
  while(#t)
    let line = read-line(*standard-input*);
    let event = 
      select(line by \=)
        "po" => #"passive-open";
        "ao" => #"active-open";
        "c" => #"close";
        "s" => #"syn-received";
        "sa" => #"syn-ack-received";
        "r" => #"rst-received";
        "f" => #"fin-received";
        "a" => #"ack-received";
        "fa" => #"fin-ack-received";
      end;
    process-event(tcp, event);
  end
end;
*/

/*
closed; application: open; syn-sent; frame: syn
listen; frame: syn; syn-received; frame: syn & ack
syn-received; frame: ack; established;
established; frame: fin; close-wait; frame: ack
syn-sent; timeout: 300; closed;
syn-sent; application: close; closed;
*/



