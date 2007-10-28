module: layer

define class <dhcp-client> (<filter>, <dhcp-client-state>)
  slot send-socket, init-keyword: send-socket:;
end;

define method push-data-aux (input :: <push-input>,
                             node :: <dhcp-client>,
                             frame :: <dhcp-message>)
  let message-type-frame = find-option(frame, <dhcp-message-type-option>);
  if (instance?(node.state, <selecting>))
    if (frame.operation = 2)
      if (message-type-frame.message-type = 2)
        node.offer := frame;
        process-event(node, #"receive-offer");
        process-event(node, #"send-request");
      end;
    end;
  end;
  if (instance?(node.state, type-union(<requesting>, <rebinding>,
                                       <renewing>, <rebooting>)))
    if (frame.operation = 2)
      if (message-type-frame.message-type = 5) //ack
        process-event(node, #"receive-ack");
        format-out("received ack %s\n", as(<string>, frame));
      elseif (message-type-frame.message-type = 6) //nak
        process-event(node, #"receive-nak")
      end
    end
  end
end;

define constant $hardware-address
  = make(<raw-frame>,
         data: mac-address("00:de:ad:be:ef:00").data);

define constant $broadcast-address = ipv4-address("255.255.255.255");

define method state-transition (state :: <dhcp-client>,
                                old-state :: <init>,
                                new-state :: <selecting>) => ()
  let random = random(2 ^ 16 - 1);
  let (r1, r2) = values(logand(#xff, ash(random, -2)), logand(#xff, random));
  let transaction-id = big-endian-unsigned-integer-4byte(list(#xde,#xad,r1,r2));
  state.xid := transaction-id;
  let packet = make(<dhcp-message>,
                    transaction-id: state.xid,
                    client-hardware-address: $hardware-address,
                    dhcp-options: list(make(<dhcp-message-type-option>,
                                            message-type: 1)));
  send(state.send-socket, $broadcast-address, packet);
end;


define function find-option (dhcp :: <dhcp-message>, option-class)
 => (res)
  block(ret)
    for (i in dhcp.dhcp-options)
      if (instance?(i, option-class))
        ret(i)
      end
    end
  end
end;

define method state-transition (state :: <dhcp-client-state>,
                                old-state :: <selecting>,
                                new-state :: <requesting>) => ()
//  if (matches-requirements?(state.offer))
  let server-option = find-option(state.offer, <dhcp-server-identifier-option>);
  let packet = make(<dhcp-message>,
                    transaction-id: state.xid,
                    client-hardware-address: $hardware-address,
                    dhcp-options: list(make(<dhcp-message-type-option>,
                                            message-type: 3),
                                       make(<dhcp-requested-ip-address-option>,
                                            requested-ip: state.offer.your-ip-address),
                                       make(<dhcp-server-identifier-option>,
                                            selected-server: server-option.selected-server)));
  send(state.send-socket, $broadcast-address, packet);
//
end;


define method main()
  let eth = build-ethernet-layer("Intel", promiscuous?: #t);
  let ip-layer = build-ip-layer(eth);
  let udp = make(<udp-layer>, ip-layer: ip-layer);
  let socket = create-socket(udp, 67, client-port: 68);
  let dhcp = make(<dhcp-client>, send-socket: socket);
  connect(socket.decapsulator, dhcp);
  process-event(dhcp, #"send-discover");
  sleep(10000);
end;

//main();
