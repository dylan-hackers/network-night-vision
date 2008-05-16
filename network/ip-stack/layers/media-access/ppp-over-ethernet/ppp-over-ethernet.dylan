module: ppp-over-ethernet

define open generic @administrative-state (layer :: <pppoe-client-layer>) => (res :: <symbol>);
define open generic @administrative-state-setter (new-value :: <symbol>, layer :: <pppoe-client-layer>) => (res :: <symbol>);
define open generic @running-state (layer :: <pppoe-client-layer>) => (res :: <symbol>);
define open generic @running-state-setter (new-value :: <symbol>, layer :: <pppoe-client-layer>) => (res :: <symbol>);
define open generic @session-id (layer :: <pppoe-client-layer>) => (res :: <integer>);
define open generic @session-id-setter (new-value :: <integer>, layer :: <pppoe-client-layer>) => (res :: <integer>);

define layer pppoe-client (<layer>, <pppoe-client-abstract-state-machine>)
  property administrative-state :: <symbol> = #"down";
  system property running-state :: <symbol> = #"down";
  system property session-id :: <integer> = 0;
  slot lower-discovery-socket :: false-or(<socket>) = #f;
  slot lower-session-socket :: false-or(<socket>) = #f;
  slot property-changed-callback :: <function>;
  slot offer;
end;

define method initialize-layer (layer :: <pppoe-client-layer>, #key, #all-keys) => ();
  local method call (event :: <property-changed-event>)
          let new-val = event.property-changed-event-property.property-value;
          process-event(layer, if (new-val == #"up")
                                 #"administrative-up"
                               elseif (new-val == #"down")
                                 #"administrative-down"
                               end);
        end;
  register-property-changed-event(layer, #"administrative-state", call);
end;
define method check-upper-layer? (lower :: <pppoe-client-layer>, upper :: <layer>) => (allowed? :: <boolean>);
  #t;
end;

define method check-lower-layer? (upper :: <pppoe-client-layer>, lower :: <layer>) => (allowed? :: <boolean>);
  upper.@running-state == #"down" /* &
    check-socket-arguments?(lower, type: <pppoe-discovery>) &
    check-socket-arguments?(lower, type: <pppoe-session>) */
end;

define function process-incoming-pppoe-discovery (node :: <pppoe-client-layer>, frame :: <pppoe-discovery>)
  if (instance?(node.state, <padi-sent>))
    if (frame.pppoe-code == #"PADO (PPPoE Active Discovery Offer)")
      node.offer := frame;
      process-event(node, #"pado-received");
    end;
  end;
  if (instance?(node.state, <padr-sent>))
    if (frame.pppoe-code == #"PADS (PPPoE Active Discovery Session-confirmation)")
      node.@session-id := frame.pppoe-session-id;
      process-event(node, #"valid-pads-received");
    end;
  end;
  if (instance?(node.state, <established>))
    if (frame.pppoe-code == #"PADT (PPPoE Active Discovery Termination)")
      process-event(node, #"padt-received");
    end;
  end;
end;

define method register-lower-layer (upper :: <pppoe-client-layer>, lower :: <layer>)
  upper.property-changed-callback := method(event :: <property-changed-event>)
                                       if(event.property-changed-event-property.property-value == #"up")
                                         process-event(upper, #"lower-layer-up")
                                       else
                                         process-event(upper, #"lower-layer-down")
                                       end;
                                     end;
  register-property-changed-event(lower, #"running-state", upper.property-changed-callback, owner: upper);
end;

define method deregister-lower-layer (upper :: <pppoe-client-layer>, lower :: <layer>)
  deregister-property-changed-event(lower, #"running-state", upper.property-changed-callback);
  close-socket(upper.lower-discovery-socket);
  upper.@running-state := #"down";
end;

define constant $broadcast-ethernet-address = mac-address("ff:ff:ff:ff:ff:ff");

define method state-transition (node :: <pppoe-client-layer>,
                                old-state :: type-union(<waiting-for-carrier>, <waiting-for-administrative-up>, <established>),
                                event,
                                new-state :: <padi-sent>) => ()
  node.lower-discovery-socket := create-socket(node.lower-layers[0], filter-string: "pppoe-discovery");
  let closure-node = make(<closure-node>, closure: curry(process-incoming-pppoe-discovery, node));
  connect(node.lower-discovery-socket.socket-output, closure-node);
  connect(closure-node, node.lower-discovery-socket.socket-input);

  let id = as(<raw-frame>, list(random(2 ^ 8 - 1), random(2 ^ 8 - 1), 23, 42));
  let pppoe-discovery = pppoe-discovery(pppoe-code: #"PADI (PPPoE Active Discovery Initiation)",
                                        pppoe-tags: list(pppoe-service-name(),
                                                         pppoe-host-uniq(custom-data: id)));
  sendto(node.lower-discovery-socket, $broadcast-ethernet-address, pppoe-discovery);
end;
define method state-transition (node :: <pppoe-client-layer>,
                                old-state :: <padi-sent>,
                                event,
                                new-state :: <padr-sent>) => ()
  let pppoe = pppoe-discovery(pppoe-code: #"PADR (PPPoE Active Discovery Request)",
                              pppoe-tags: node.offer.pppoe-tags);
  sendto(node.lower-discovery-socket, node.offer.parent.source-address, pppoe);
end;

define method state-transition (node :: <pppoe-client-layer>,
                                old-state :: <pppoe-state>,
                                event,
                                new-state :: <established>) => ()
  let filter = format-to-string("pppoe-session.session-id = %d", node.@session-id);
  node.lower-session-socket := create-socket(node.lower-layers[0], filter-string: filter);
  node.@running-state := #"up";
end;

define method state-transition (node :: <pppoe-client-layer>,
                                old-state :: <established>,
                                event,
                                new-state :: <waiting-for-administrative-up>) => ()
  let pppoe = pppoe-discovery(pppoe-code: #"PADT (PPPoE Active Discovery Termination)",
                              session-id: node.@session-id);
  sendto(node.lower-discovery-socket, node.offer.parent.source-address, pppoe);
end;
