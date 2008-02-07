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
                                old-state :: <closed>,
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
                                new-state :: <padr-sent>) => ()
  let pppoe = pppoe-discovery(pppoe-code: #"PADR (PPPoE Active Discovery Request)",
                              pppoe-tags: node.offer.pppoe-tags);
  send(node.send-socket, node.offer.parent.source-address, pppoe);
end;

define method state-transition (node :: <pppoe-client>,
                                old-state :: <established>,
                                new-state :: <closed>) => ()
  let pppoe = pppoe-discovery(pppoe-code: #"PADT (PPPoE Active Discovery Termination)",
                              session-id: node.my-session-id);
  send(node.send-socket, node.offer.parent.source-address, pppoe);
end;

