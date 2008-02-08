module: layer

define class <pppoe-client> (<filter>, <pppoe-client-abstract-state-machine>)
  slot send-socket, init-keyword: send-socket:;
  slot host-id :: <raw-frame>;
  slot offer;
  slot my-session-id :: <integer>;
end;


define method push-data-aux (input :: <push-input>,
                             node :: <pppoe-client>,
                             frame :: <pppoe-discovery>)
  if (instance?(node.state, <padi-sent>))
    if (frame.pppoe-code == #"PADO (PPPoE Active Discovery Offer)")
      node.offer := frame;
      process-event(node, #"pado-received");
      process-event(node, #"padr-sent");
    end;
  end;
  if (instance?(node.state, <padr-sent>))
    if (frame.pppoe-code == #"PADS (PPPoE Active Discovery Session-confirmation)")
      node.my-session-id := frame.session-id;
      process-event(node, #"valid-pads-received");
      process-event(node, #"abort");
    end;
  end;
  if (instance?(node.state, <established>))
    if (frame.pppoe-code == #"PADT (PPPoE Active Discovery Termination)")
      process-event(node, #"padt-received");
    end;
  end;
end;


define method state-transition (node :: <pppoe-client>,
                                old-state :: <down>,
                                event,
                                new-state :: <padi-sent>) => ()
  let id = as(<raw-frame>, list(random(2 ^ 8 - 1), random(2 ^ 8 - 1), 23, 42));
  node.host-id := id;
  let pppoe-discovery = pppoe-discovery(pppoe-code: #"PADI (PPPoE Active Discovery Initiation)",
                                        pppoe-tags: list(pppoe-service-name(),
                                                         pppoe-host-uniq(custom-data: id)));
  send(node.send-socket, $broadcast-ethernet-address, pppoe-discovery);
end;
define method state-transition (node :: <pppoe-client>,
                                old-state :: <pado-received>,
                                event,
                                new-state :: <padr-sent>) => ()
  let pppoe = pppoe-discovery(pppoe-code: #"PADR (PPPoE Active Discovery Request)",
                              pppoe-tags: node.offer.pppoe-tags);
  send(node.send-socket, node.offer.parent.source-address, pppoe);
end;

define method state-transition (node :: <pppoe-client>,
                                old-state :: <established>,
                                event,
                                new-state :: <down>) => ()
  let pppoe = pppoe-discovery(pppoe-code: #"PADT (PPPoE Active Discovery Termination)",
                              session-id: node.my-session-id);
  send(node.send-socket, node.offer.parent.source-address, pppoe);
end;

define class <ppp-session> (<filter>, <ppp-abstract-state-machine>)
  slot send-socket, init-keyword: send-socket:;
  slot my-magic;
  slot last-request;
end;

define function send-ppp (ppp :: <ppp-session>, frame :: <container-frame>)
  format-out("sending %=\n", frame);
end;
define macro ppp-transition-definer
  {
    define ppp-transition (?old:expression ?ev:expression ?new:name)
      ?actions:*
    end
  } => {
    define method state-transition (?=ppp-session :: <ppp-session>,
                                    ?=old-state :: ?old,
                                    ?=event == ?ev,
                                    ?=new-state :: ?new,
                                    #next next-method) => ();
      let ?=tlu = curry(this-layer-up, ?=ppp-session);
      let ?=tld = curry(this-layer-down, ?=ppp-session);
      let ?=tls = curry(this-layer-started, ?=ppp-session);
      let ?=tlf = curry(this-layer-finished, ?=ppp-session);
      let ?=irc = curry(initialize-restart-count, ?=ppp-session);
      let ?=zrc = curry(zero-restart-count, ?=ppp-session);
      let ?=scr = curry(send-configure-request, ?=ppp-session);
      let ?=sca = curry(send-configure-ack, ?=ppp-session);
      let ?=scn = curry(send-configure-nak, ?=ppp-session);
      let ?=str = curry(send-terminate-request, ?=ppp-session);
      let ?=sta = curry(send-terminate-ack, ?=ppp-session);
      let ?=scj = curry(send-code-reject, ?=ppp-session);
      let ?=ser = curry(send-echo-reply, ?=ppp-session);
      do(method (x) x() end, list(?actions));
      next-method();
    end
  }
end;

define function this-layer-up (session :: <ppp-session>)
  format-out("PPP layer went up\n");
end;

define function this-layer-down (session :: <ppp-session>)
  format-out("PPP layer went down\n");
end;

define function this-layer-started (session :: <ppp-session>)
  format-out("PPP layer started\n");
end;

define function this-layer-finished (session :: <ppp-session>)
  format-out("PPP layer finished\n");
end;

define function initialize-restart-count (session :: <ppp-session>)
end;

define function zero-restart-count (session :: <ppp-session>)
end;

define function send-configure-request (session :: <ppp-session>)
  send-ppp(session, lcp-configure-request());
end;

define function send-configure-ack (session :: <ppp-session>)
  send-ppp(session, lcp-configure-ack());
end;

define function send-configure-nak (session :: <ppp-session>)
  send-ppp(session, lcp-configure-nak());
end;

define function send-terminate-request (session :: <ppp-session>)
  send-ppp(session, lcp-terminate-request());
end;

define function send-terminate-ack (session :: <ppp-session>)
  send-ppp(session, lcp-terminate-ack());
end;

define function send-code-reject (session :: <ppp-session>)
  send-ppp(session, lcp-code-reject());
end;

define function send-echo-reply (session :: <ppp-session>)
  send-ppp(session, lcp-echo-reply(magic-number: session.my-magic,
                                   custom-data: session.last-request.custom-data));
end;

define ppp-transition ( <initial> #"administrative-open" <starting> ) tls end;

define ppp-transition ( <starting> #"lower-layer-up" <request-sent> ) irc, scr end;
define ppp-transition ( <starting> #"administrative-close" <initial> ) tlf end;

define ppp-transition ( <closed> #"administrative-open" <request-sent> ) irc, scr end;
define ppp-transition ( <closed> #"receive-configure-request-good" <closed> ) sta end;
define ppp-transition ( <closed> #"receive-configure-request-bad" <closed> ) sta end;
define ppp-transition ( <closed> #"receive-configure-ack" <closed> ) sta end;
define ppp-transition ( <closed> #"receive-configure-nak" <closed> ) sta end;
define ppp-transition ( <closed> #"receive-terminate-request" <closed> ) sta end;
define ppp-transition ( <closed> #"receive-unknown-code" <closed> ) scj end;
define ppp-transition ( <closed> #"receive-code-or-protocol-reject-catastrophic" <closed> ) tlf end;

define ppp-transition ( <stopped> #"lower-layer-down" <starting> ) tls end;
define ppp-transition ( <stopped> #"receive-configure-request-good" <ack-sent> ) irc, scr, sca end;
define ppp-transition ( <stopped> #"receive-configure-request-bad" <request-sent> ) irc, scr, scn end;
define ppp-transition ( <stopped> #"receive-configure-ack" <stopped> ) sta end;
define ppp-transition ( <stopped> #"receive-configure-nak" <stopped> ) sta end;
define ppp-transition ( <stopped> #"receive-terminate-request" <stopped> ) sta end;
define ppp-transition ( <stopped> #"receive-unknown-code" <stopped> ) scj end;
define ppp-transition ( <stopped> #"receive-code-or-protocol-reject-catastrophic" <stopped> ) tlf end;

define ppp-transition ( <closing> #"timeout-with-counter->0" <closing> ) str end;
define ppp-transition ( <closing> #"timeout-with-counter-expired" <closed> ) tlf end;
define ppp-transition ( <closing> #"receive-terminate-request" <closing> ) sta end;
define ppp-transition ( <closing> #"receive-terminate-ack" <closed> ) tlf end;
define ppp-transition ( <closing> #"receive-unknown-code" <closing> ) scj end;
define ppp-transition ( <closing> #"receive-code-or-protocol-reject-catastrophic" <closed> ) tlf end;

define ppp-transition ( <stopping> #"timeout-with-counter->0" <stopping> ) str end;
define ppp-transition ( <stopping> #"timeout-with-counter-expired" <stopped> ) tlf end;
define ppp-transition ( <stopping> #"receive-terminate-request" <stopping> ) sta end;
define ppp-transition ( <stopping> #"receive-terminate-ack" <stopped> ) tlf end;
define ppp-transition ( <stopping> #"receive-unknown-code" <stopping> ) scj end;
define ppp-transition ( <stopping> #"receive-code-or-protocol-reject-catastrophic" <stopped> ) tlf end;

define ppp-transition ( <request-sent> #"administrative-close" <closing> ) irc, str end;
define ppp-transition ( <request-sent> #"timeout-with-counter->0" <request-sent> ) scr end;
define ppp-transition ( <request-sent> #"timeout-with-counter-expired" <stopped> ) tlf end;
define ppp-transition ( <request-sent> #"receive-configure-request-good" <ack-sent> ) sca end;
define ppp-transition ( <request-sent> #"receive-configure-request-bad" <request-sent> ) scn end;
define ppp-transition ( <request-sent> #"receive-configure-ack" <ack-received> ) irc end;
define ppp-transition ( <request-sent> #"receive-configure-nak" <request-sent> ) irc, scr end;
define ppp-transition ( <request-sent> #"receive-terminate-request" <request-sent> ) sta end;
define ppp-transition ( <request-sent> #"receive-unknown-code" <request-sent> ) scj end;
define ppp-transition ( <request-sent> #"receive-code-or-protocol-reject-catastrophic" <stopped> ) tlf end;

define ppp-transition ( <ack-received> #"administrative-close" <closing> ) irc, str end;
define ppp-transition ( <ack-received> #"timeout-with-counter->0" <request-sent> ) scr end;
define ppp-transition ( <ack-received> #"timeout-with-counter-expired" <stopped> ) tlf end;
define ppp-transition ( <ack-received> #"receive-configure-request-good" <opened> ) sca, tlu end;
define ppp-transition ( <ack-received> #"receive-configure-request-bad" <ack-received> ) scn end;
define ppp-transition ( <ack-received> #"receive-configure-ack" <request-sent> ) scr end;
define ppp-transition ( <ack-received> #"receive-configure-nak" <request-sent> ) scr end;
define ppp-transition ( <ack-received> #"receive-terminate-request" <request-sent> ) sta end;
define ppp-transition ( <ack-received> #"receive-unknown-code" <ack-received> ) scj end;
define ppp-transition ( <ack-received> #"receive-code-or-protocol-reject-catastrophic" <stopped> ) tlf end;

define ppp-transition ( <ack-sent> #"administrative-close" <closing> ) irc, str end;
define ppp-transition ( <ack-sent> #"timeout-with-counter->0" <ack-sent> ) scr end;
define ppp-transition ( <ack-sent> #"timeout-with-counter-expired" <stopped> ) tlf end;
define ppp-transition ( <ack-sent> #"receive-configure-request-good" <ack-sent> ) sca end;
define ppp-transition ( <ack-sent> #"receive-configure-request-bad" <request-sent> ) scn end;
define ppp-transition ( <ack-sent> #"receive-configure-ack" <opened> ) irc, tlu end;
define ppp-transition ( <ack-sent> #"receive-configure-nak" <ack-sent> ) irc, scr end;
define ppp-transition ( <ack-sent> #"receive-terminate-request" <request-sent> ) sta end;
define ppp-transition ( <ack-sent> #"receive-unknown-code" <ack-sent> ) scj end;
define ppp-transition ( <ack-sent> #"receive-code-or-protocol-reject-catastrophic" <stopped> ) tlf end;

define ppp-transition ( <opened> #"lower-layer-down" <starting> ) tld end;
define ppp-transition ( <opened> #"administrative-close" <closing> ) tld, irc, str end;
define ppp-transition ( <opened> #"receive-configure-request-good" <ack-sent> ) tld, scr, sca end;
define ppp-transition ( <opened> #"receive-configure-request-bad" <request-sent> ) tld, scr, scn end;
define ppp-transition ( <opened> #"receive-configure-ack" <request-sent> ) tld, scr end;
define ppp-transition ( <opened> #"receive-configure-nak" <request-sent> ) tld, scr end;
define ppp-transition ( <opened> #"receive-terminate-request" <stopping> ) tld, zrc, sta end;
define ppp-transition ( <opened> #"receive-terminate-ack" <request-sent> ) tld, scr end;
define ppp-transition ( <opened> #"receive-unknown-code" <opened> ) scj end;
define ppp-transition ( <opened> #"receive-code-or-protocol-reject-catastrophic" <stopping> ) tld, irc, str end;
define ppp-transition ( <opened> #"receive-echo-or-discard" <opened> ) ser end;

