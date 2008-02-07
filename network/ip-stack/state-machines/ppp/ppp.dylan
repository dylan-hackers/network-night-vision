Module:    ppp-state-machine
Copyright: (c) 2008 Dylan Hackers

define open class <pppoe-client-abstract-state-machine> (<protocol-state-encapsulation>)
  inherited slot state = make(<closed>);
end;

define abstract class <pppoe-state> (<protocol-state>) end;

states(<closed>, <padi-sent>, <pado-received>, <padr-sent>, <established>; <pppoe-state>);

define constant <pppoe-events>
  = one-of(#"padi-sent", #"pado-received", #"padr-sent", #"valid-pads-received",
           #"invalid-pads-received", #"padt-received", #"abort");

define state-transition-rule <closed> #"padi-sent" <padi-sent> end;

define state-transition-rule <padi-sent> #"pado-received" <pado-received> end;

define state-transition-rule <pado-received> #"padr-sent" <padr-sent> end;

define state-transition-rule <padr-sent> #"valid-pads-received" <established> end;

define state-transition-rule <padr-sent> #"invalid-pads-received" <closed> end;

define state-transition-rule <established> #"padt-received" <closed> end;

define state-transition-rule <pppoe-state> #"abort" <closed> end;




