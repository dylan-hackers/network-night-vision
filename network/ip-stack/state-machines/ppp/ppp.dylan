Module:    ppp-state-machine
Copyright: (c) 2008 Dylan Hackers

define open class <pppoe-client-abstract-state-machine> (<protocol-state-encapsulation>)
  inherited slot state = make(<down>);
end;

define abstract class <pppoe-state> (<protocol-state>) end;

states(<down>, <waiting-for-administrative-up>, <waiting-for-carrier>,
       <padi-sent>, <padr-sent>, <established>; <pppoe-state>);

define constant <pppoe-events>
  = one-of(#"lower-layer-up", #"pado-received", #"valid-pads-received",
           #"invalid-pads-received", #"padt-received", #"lower-layer-down",
           #"administrative-up", #"administrative-down");

define state-transition-rule <down> #"lower-layer-up" <waiting-for-administrative-up> end;
define state-transition-rule <waiting-for-carrier> #"lower-layer-up" <padi-sent> end;
define state-transition-rule <waiting-for-administrative-up> #"administrative-up" <padi-sent> end;
define state-transition-rule <down> #"administrative-up" <waiting-for-carrier> end;

define state-transition-rule <padi-sent> #"pado-received" <padr-sent> end;

define state-transition-rule <padr-sent> #"valid-pads-received" <established> end;

define state-transition-rule <padr-sent> #"invalid-pads-received" <down> end;

define state-transition-rule <established> #"padt-received" <padi-sent> end;

define state-transition-rule <pppoe-state> #"lower-layer-down" <down> end;
define state-transition-rule <pppoe-state> #"administrative-down" <waiting-for-administrative-up> end;
define state-transition-rule <down> #"administrative-down" <down> end;


define open class <ppp-abstract-state-machine> (<protocol-state-encapsulation>)
  inherited slot state = make(<initial>);
end;

define abstract class <ppp-state> (<protocol-state>) end;

states(<initial>, <starting>, <closed>, <stopped>, <closing>, <stopping>,
       <request-sent>, <ack-received>, <ack-sent>, <opened>; <ppp-state>);

define constant <ppp-events>
  = one-of(#"lower-layer-up", #"lower-layer-down", #"administrative-open", #"administrative-close",
           #"timeout-with-counter->0", #"timeout-with-counter-expired", 
           #"receive-configure-request-good", #"receive-configure-request-bad",
           #"receive-configure-ack", #"receive-configure-nak",
           #"receive-terminate-request", #"receive-terminate-ack",
           #"receive-unknown-code",
           #"receive-code-or-protocol-reject-permitted",
           #"receive-code-or-protocol-reject-catastrophic",
           #"receive-echo-or-discard");

define state-transition-rule <initial> #"lower-layer-up" <closed> end;
define state-transition-rule <initial> #"administrative-open" <starting> end;
define state-transition-rule <initial> #"administrative-close" <initial> end;

define state-transition-rule <starting> #"lower-layer-up" <request-sent> end;
define state-transition-rule <starting> #"administrative-open" <starting> end;
define state-transition-rule <starting> #"administrative-close" <initial> end;

define state-transition-rule <closed> #"lower-layer-down" <initial> end;
define state-transition-rule <closed> #"administrative-open" <request-sent> end;
define state-transition-rule <closed> #"administrative-close" <closed> end;
define state-transition-rule <closed> #"receive-configure-request-good" <closed> end;
define state-transition-rule <closed> #"receive-configure-request-bad" <closed> end;
define state-transition-rule <closed> #"receive-configure-ack" <closed> end;
define state-transition-rule <closed> #"receive-configure-nak" <closed> end;
define state-transition-rule <closed> #"receive-terminate-request" <closed> end;
define state-transition-rule <closed> #"receive-terminate-ack" <closed> end;
define state-transition-rule <closed> #"receive-unknown-code" <closed> end;
define state-transition-rule <closed> #"receive-code-or-protocol-reject-permitted" <closed> end;
define state-transition-rule <closed> #"receive-code-or-protocol-reject-catastrophic" <closed> end;
define state-transition-rule <closed> #"receive-echo-or-discard" <closed> end;

define state-transition-rule <stopped> #"lower-layer-down" <starting> end;
define state-transition-rule <stopped> #"administrative-open" <stopped> end;
define state-transition-rule <stopped> #"administrative-close" <closed> end;
define state-transition-rule <stopped> #"receive-configure-request-good" <ack-sent> end;
define state-transition-rule <stopped> #"receive-configure-request-bad" <request-sent> end;
define state-transition-rule <stopped> #"receive-configure-ack" <stopped> end;
define state-transition-rule <stopped> #"receive-configure-nak" <stopped> end;
define state-transition-rule <stopped> #"receive-terminate-request" <stopped> end;
define state-transition-rule <stopped> #"receive-terminate-ack" <stopped> end;
define state-transition-rule <stopped> #"receive-unknown-code" <stopped> end;
define state-transition-rule <stopped> #"receive-code-or-protocol-reject-permitted" <stopped> end;
define state-transition-rule <stopped> #"receive-code-or-protocol-reject-catastrophic" <stopped> end;
define state-transition-rule <stopped> #"receive-echo-or-discard" <stopped> end;

define state-transition-rule <closing> #"lower-layer-down" <initial> end;
define state-transition-rule <closing> #"administrative-open" <stopping> end;
define state-transition-rule <closing> #"administrative-close" <closing> end;
define state-transition-rule <closing> #"timeout-with-counter->0" <closing> end;
define state-transition-rule <closing> #"timeout-with-counter-expired" <closed> end;
define state-transition-rule <closing> #"receive-configure-request-good" <closing> end;
define state-transition-rule <closing> #"receive-configure-request-bad" <closing> end;
define state-transition-rule <closing> #"receive-configure-ack" <closing> end;
define state-transition-rule <closing> #"receive-configure-nak" <closing> end;
define state-transition-rule <closing> #"receive-terminate-request" <closing> end;
define state-transition-rule <closing> #"receive-terminate-ack" <closed> end;
define state-transition-rule <closing> #"receive-unknown-code" <closing> end;
define state-transition-rule <closing> #"receive-code-or-protocol-reject-permitted" <closing> end;
define state-transition-rule <closing> #"receive-code-or-protocol-reject-catastrophic" <closed> end;
define state-transition-rule <closing> #"receive-echo-or-discard" <closing> end;

define state-transition-rule <stopping> #"lower-layer-down" <starting> end;
define state-transition-rule <stopping> #"administrative-open" <stopping> end;
define state-transition-rule <stopping> #"administrative-close" <closing> end;
define state-transition-rule <stopping> #"timeout-with-counter->0" <stopping> end;
define state-transition-rule <stopping> #"timeout-with-counter-expired" <stopped> end;
define state-transition-rule <stopping> #"receive-configure-request-good" <stopping> end;
define state-transition-rule <stopping> #"receive-configure-request-bad" <stopping> end;
define state-transition-rule <stopping> #"receive-configure-ack" <stopping> end;
define state-transition-rule <stopping> #"receive-configure-nak" <stopping> end;
define state-transition-rule <stopping> #"receive-terminate-request" <stopping> end;
define state-transition-rule <stopping> #"receive-terminate-ack" <stopped> end;
define state-transition-rule <stopping> #"receive-unknown-code" <stopping> end;
define state-transition-rule <stopping> #"receive-code-or-protocol-reject-permitted" <stopping> end;
define state-transition-rule <stopping> #"receive-code-or-protocol-reject-catastrophic" <stopped> end;
define state-transition-rule <stopping> #"receive-echo-or-discard" <stopping> end;

define state-transition-rule <request-sent> #"lower-layer-down" <starting> end;
define state-transition-rule <request-sent> #"administrative-open" <request-sent> end;
define state-transition-rule <request-sent> #"administrative-close" <closing> end;
define state-transition-rule <request-sent> #"timeout-with-counter->0" <request-sent> end;
define state-transition-rule <request-sent> #"timeout-with-counter-expired" <stopped> end;
define state-transition-rule <request-sent> #"receive-configure-request-good" <ack-sent> end;
define state-transition-rule <request-sent> #"receive-configure-request-bad" <request-sent> end;
define state-transition-rule <request-sent> #"receive-configure-ack" <ack-received> end;
define state-transition-rule <request-sent> #"receive-configure-nak" <request-sent> end;
define state-transition-rule <request-sent> #"receive-terminate-request" <request-sent> end;
define state-transition-rule <request-sent> #"receive-terminate-ack" <request-sent> end;
define state-transition-rule <request-sent> #"receive-unknown-code" <request-sent> end;
define state-transition-rule <request-sent> #"receive-code-or-protocol-reject-permitted" <request-sent> end;
define state-transition-rule <request-sent> #"receive-code-or-protocol-reject-catastrophic" <stopped> end;
define state-transition-rule <request-sent> #"receive-echo-or-discard" <request-sent> end;

define state-transition-rule <ack-received> #"lower-layer-down" <starting> end;
define state-transition-rule <ack-received> #"administrative-open" <ack-received> end;
define state-transition-rule <ack-received> #"administrative-close" <closing> end;
define state-transition-rule <ack-received> #"timeout-with-counter->0" <request-sent> end;
define state-transition-rule <ack-received> #"timeout-with-counter-expired" <stopped> end;
define state-transition-rule <ack-received> #"receive-configure-request-good" <opened> end;
define state-transition-rule <ack-received> #"receive-configure-request-bad" <ack-received> end;
define state-transition-rule <ack-received> #"receive-configure-ack" <request-sent> end;
define state-transition-rule <ack-received> #"receive-configure-nak" <request-sent> end;
define state-transition-rule <ack-received> #"receive-terminate-request" <request-sent> end;
define state-transition-rule <ack-received> #"receive-terminate-ack" <request-sent> end;
define state-transition-rule <ack-received> #"receive-unknown-code" <ack-received> end;
define state-transition-rule <ack-received> #"receive-code-or-protocol-reject-permitted" <request-sent> end;
define state-transition-rule <ack-received> #"receive-code-or-protocol-reject-catastrophic" <stopped> end;
define state-transition-rule <ack-received> #"receive-echo-or-discard" <ack-received> end;

define state-transition-rule <ack-sent> #"lower-layer-down" <starting> end;
define state-transition-rule <ack-sent> #"administrative-open" <ack-sent> end;
define state-transition-rule <ack-sent> #"administrative-close" <closing> end;
define state-transition-rule <ack-sent> #"timeout-with-counter->0" <ack-sent> end;
define state-transition-rule <ack-sent> #"timeout-with-counter-expired" <stopped> end;
define state-transition-rule <ack-sent> #"receive-configure-request-good" <ack-sent> end;
define state-transition-rule <ack-sent> #"receive-configure-request-bad" <request-sent> end;
define state-transition-rule <ack-sent> #"receive-configure-ack" <opened> end;
define state-transition-rule <ack-sent> #"receive-configure-nak" <ack-sent> end;
define state-transition-rule <ack-sent> #"receive-terminate-request" <request-sent> end;
define state-transition-rule <ack-sent> #"receive-terminate-ack" <ack-sent> end;
define state-transition-rule <ack-sent> #"receive-unknown-code" <ack-sent> end;
define state-transition-rule <ack-sent> #"receive-code-or-protocol-reject-permitted" <ack-sent> end;
define state-transition-rule <ack-sent> #"receive-code-or-protocol-reject-catastrophic" <stopped> end;
define state-transition-rule <ack-sent> #"receive-echo-or-discard" <ack-sent> end;

define state-transition-rule <opened> #"lower-layer-down" <starting> end;
define state-transition-rule <opened> #"administrative-open" <opened> end;
define state-transition-rule <opened> #"administrative-close" <closing> end;
define state-transition-rule <opened> #"receive-configure-request-good" <ack-sent> end;
define state-transition-rule <opened> #"receive-configure-request-bad" <request-sent> end;
define state-transition-rule <opened> #"receive-configure-ack" <request-sent> end;
define state-transition-rule <opened> #"receive-configure-nak" <request-sent> end;
define state-transition-rule <opened> #"receive-terminate-request" <stopping> end;
define state-transition-rule <opened> #"receive-terminate-ack" <request-sent> end;
define state-transition-rule <opened> #"receive-unknown-code" <opened> end;
define state-transition-rule <opened> #"receive-code-or-protocol-reject-permitted" <opened> end;
define state-transition-rule <opened> #"receive-code-or-protocol-reject-catastrophic" <stopping> end;
define state-transition-rule <opened> #"receive-echo-or-discard" <opened> end;

