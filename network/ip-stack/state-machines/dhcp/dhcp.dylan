Module: dhcp-state-machine
Author:    Hannes Mehnert
Copyright: (C) 2007,  All rights reversed.

define abstract class <dhcp-state> (<protocol-state>) end;

define open class <dhcp-client-state> (<protocol-state-encapsulation>)
  inherited slot state = make(<init>);
  slot xid;
  slot offer;
end;

states(<init-reboot>, <rebooting>, <requesting>, <init>,
       <selecting>, <rebinding>, <bound>, <renewing>; <dhcp-state>);

define constant <dhcp-events>
  = one-of(#"send-discover", #"send-request", #"receive-nak", #"receive-ack",
           #"receive-offer", #"receive-ack-send-decline", #"timeout-t1-expires",
           #"timeout-t2-expires", #"lease-expired");

define state-transition-rule <init> #"send-discover" <selecting> end;
define state-transition-rule <init-reboot> #"send-request" <rebooting> end;
define state-transition-rule <rebooting> #"receive-nak" <init> end;
define state-transition-rule <rebooting> #"receive-ack" <bound> end;
define state-transition-rule <selecting> #"send-request" <requesting> end;
define state-transition-rule <selecting> #"receive-offer" <selecting> end;
define state-transition-rule <requesting> #"receive-offer" <requesting> end;
define state-transition-rule <requesting> #"receive-nak" <init> end;
define state-transition-rule <requesting> #"receive-ack" <bound> end;
define state-transition-rule <requesting> #"receive-ack-send-decline" <init> end;
define state-transition-rule <bound> #"receive-offer" <bound> end;
define state-transition-rule <bound> #"receive-ack" <bound> end;
define state-transition-rule <bound> #"receive-nak" <bound> end;
define state-transition-rule <bound> #"timeout-t1-expires" <renewing> end;
define state-transition-rule <rebinding> #"receive-ack" <bound> end;
define state-transition-rule <rebinding> #"receive-nak" <init> end;
define state-transition-rule <rebinding> #"lease-expired" <init> end;
define state-transition-rule <renewing> #"receive-ack" <bound> end;
define state-transition-rule <renewing> #"timeout-t2-expires" <rebinding> end;
define state-transition-rule <renewing> #"receive-nak" <init> end;

