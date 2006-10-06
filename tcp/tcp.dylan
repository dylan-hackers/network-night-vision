Module:    tcp
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define open class <tcp-dingens> (<object>)
  slot state :: <tcp-state> = make(<closed>);
end;

define abstract class <tcp-state> (<object>)
end;

define class <closed> (<tcp-state>)
end;

define class <listen> (<tcp-state>)
end;




define class <syn-sent> (<tcp-state>)
end;

define class <syn-received> (<tcp-state>)
end;

define class <established> (<tcp-state>)
end;

define class <fin-wait1> (<tcp-state>)
end;

define class <fin-wait2> (<tcp-state>)
end;

define class <closing> (<tcp-state>)
end;

define class <time-wait> (<tcp-state>)
end;

define class <close-wait> (<tcp-state>)
end;

define class <last-ack> (<tcp-state>)
end;

define open generic passive-open (dingens :: type-union(<tcp-dingens>, <tcp-state>)) => (new-state :: <tcp-state>);

define open generic active-open (dingens :: type-union(<tcp-dingens>, <tcp-state>)) => (new-state :: <tcp-state>);

define open generic close (dingens :: type-union(<tcp-dingens>, <tcp-state>)) => (new-state :: <tcp-state>);

define open generic syn-received (dingens :: type-union(<tcp-dingens>, <tcp-state>)) => (new-state :: <tcp-state>);

define open generic syn-ack-received (dingens :: type-union(<tcp-dingens>, <tcp-state>)) => (new-state :: <tcp-state>);

define open generic rst-received (dingens :: type-union(<tcp-dingens>, <tcp-state>)) => (new-state :: <tcp-state>);

define open generic fin-received (dingens :: type-union(<tcp-dingens>, <tcp-state>)) => (new-state :: <tcp-state>);

define open generic ack-received (dingens :: type-union(<tcp-dingens>, <tcp-state>)) => (new-state :: <tcp-state>);

define open generic fin-ack-received (dingens :: type-union(<tcp-dingens>, <tcp-state>)) => (new-type :: <tcp-state>);

define method passive-open (dingens :: <tcp-dingens>) => (new-state :: <tcp-state>);
  dingens.state := passive-open(dingens.state)
end;
define method active-open (dingens :: <tcp-dingens>) => (new-state :: <tcp-state>);
  dingens.state := active-open(dingens.state)
end;

define method close (dingens :: <tcp-dingens>) => (new-state :: <tcp-state>);
  dingens.state := close(dingens.state)
end;

define method syn-received (dingens :: <tcp-dingens>) => (new-state :: <tcp-state>);
  dingens.state := syn-received(dingens.state)
end;

define method syn-ack-received (dingens :: <tcp-dingens>) => (new-state :: <tcp-state>);
  dingens.state := syn-ack-received(dingens.state)
end;

define method rst-received (dingens :: <tcp-dingens>) => (new-state :: <tcp-state>);
  dingens.state := rst-received(dingens.state)
end;

define method fin-received (dingens :: <tcp-dingens>) => (new-state :: <tcp-state>);
  dingens.state := fin-received(dingens.state)
end;

define method ack-received (dingens :: <tcp-dingens>) => (new-state :: <tcp-state>);
  dingens.state := ack-received(dingens.state)
end;

define method fin-ack-received (dingens :: <tcp-dingens>) => (new-state :: <tcp-state>);
  dingens.state := fin-ack-received(dingens.state)
end;

define method passive-open (old-state :: <tcp-state>) => (new-state :: <tcp-state>);
  format-out("R\n");
  old-state
end;

define method active-open (old-state :: <tcp-state>) => (new-state :: <tcp-state>);
  format-out("R\n");
  old-state
end;

define method close (old-state :: <tcp-state>) => (new-state :: <tcp-state>);
  format-out("R\n");
  old-state
end;

define method syn-received (old-state :: <tcp-state>) => (new-state :: <tcp-state>);
  format-out("R\n");
  old-state
end;

define method syn-ack-received (old-state :: <tcp-state>) => (new-state :: <tcp-state>);
  format-out("R\n");
  old-state
end;

define method rst-received (old-state :: <tcp-state>) => (new-state :: <tcp-state>);
  format-out("R\n");
  old-state
end;

define method fin-received (old-state :: <tcp-state>) => (new-state :: <tcp-state>);
  format-out("R\n");
  old-state
end;

define method ack-received (old-state :: <tcp-state>) => (new-state :: <tcp-state>);
  format-out("R\n");
  old-state
end;

define method fin-ack-received (old-state :: <tcp-state>) => (new-state :: <tcp-state>);
  format-out("R\n");
  old-state
end;

define method passive-open (old-state :: <closed>) => (new-state :: <tcp-state>);
  format-out("Listen");
  make(<listen>)
end;

define method active-open (old-state :: <closed>) => (new-state :: <tcp-state>);
  format-out("Syn");
  make(<syn-sent>);
end;

define method syn-received (old-state :: <listen>) => (new-state :: <tcp-state>);
  format-out("SynAck");
  make(<syn-received>)
end;

define method close (old-state :: <syn-sent>) => (new-state :: <tcp-state>);
  format-out("Close");
  make(<closed>)
end;

define method syn-received (old-state :: <syn-sent>) => (new-state :: <tcp-state>);
  format-out("SynAck");
  make(<syn-received>)
end;

define method syn-ack-received (old-state :: <syn-sent>) => (new-state :: <tcp-state>);
  format-out("Ack");
  make(<established>)
end;

define method rst-received (old-state :: <syn-received>) => (new-state :: <tcp-state>);
  format-out("Rst->Listen");
  make(<listen>)
end;

define method ack-received (old-state :: <syn-received>) => (new-state :: <tcp-state>);
  format-out("Established");
  make(<established>)
end;

define method close (old-state :: <syn-received>) => (new-state :: <tcp-state>);
  format-out("FIN");
  make(<fin-wait1>)
end;

define method close (old-state :: <established>) => (new-state :: <tcp-state>);
  format-out("FIN");
  make(<fin-wait1>)
end;

define method fin-received (old-state :: <established>) => (new-state :: <tcp-state>);
  format-out("ACK");
  make(<close-wait>)
end;

define method close (old-state :: <close-wait>) => (new-state :: <tcp-state>);
  format-out("FIN");
  make(<last-ack>)
end;

define method ack-received (old-state :: <last-ack>) => (new-state :: <tcp-state>);
  format-out("Closed");
  make(<closed>)
end;

define method fin-received (old-state :: <fin-wait1>) => (new-state :: <tcp-state>);
  format-out("ACK");
  make(<closing>)
end;

define method ack-received (old-state :: <fin-wait1>) => (new-state :: <tcp-state>);
  format-out("fin-wait2");
  make(<fin-wait2>)
end;

define method fin-ack-received (old-state :: <fin-wait1>) => (new-state :: <tcp-state>);
  format-out("ACK");
  make(<time-wait>)
end;

define method fin-received (old-state :: <fin-wait2>) => (new-state :: <tcp-state>);
  format-out("ACK");
  make(<time-wait>)
end;

define method ack-received (old-state :: <closing>) => (new-state :: <tcp-state>);
  format-out("time-wait");
  make(<time-wait>)
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



