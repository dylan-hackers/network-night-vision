module: ieee802-1q

define class <dot1q-encapsulator> (<filter>)
  slot encapsulator-vlan-id :: <integer> = 0;
end;

define class <dot1q-decapsulator> (<filter>)
end;

define layer vlan (<layer>)
  inherited property administrative-state = #"up";
  property vlan-id :: <integer> = 0;
  slot dot1q-decapsulator :: <dot1q-decapsulator> = make(<dot1q-decapsulator>);
  slot dot1q-encapsulator :: <dot1q-encapsulator> = make(<dot1q-encapsulator>);
  slot fan-in :: <fan-in> = make(<fan-in>);
  slot demultiplexer :: <demultiplexer> = make(<demultiplexer>);
  slot lower-socket :: false-or(<socket>) = #f;
end;

define method initialize-layer (layer :: <vlan-layer>, #key, #all-keys) => ()
  connect(layer.dot1q-decapsulator, layer.demultiplexer);
  connect(layer.fan-in, layer.dot1q-encapsulator);
  local method change-vlan-id (event :: <property-changed-event>)
          let new-value = event.property-changed-event-property.property-value;
          layer.dot1q-encapsulator.encapsulator-vlan-id := new-value;
          if (layer.lower-socket)
            let lower = layer.lower-socket.socket-owner;
            deregister-lower-layer(layer, lower);
            register-lower-layer(layer, lower);
          end;
        end;
  register-property-changed-event(layer, #"vlan-id", change-vlan-id);
end;


define method push-data-aux (input :: <push-input>, node :: <dot1q-encapsulator>, data :: <ethernet-frame>);
  let new-frame = ethernet-frame(source-address: data.source-address,
                                 destination-address: data.destination-address,
                                 payload: vlan-tag(vlan-id: node.encapsulator-vlan-id,
                                                   type-code: data.type-code,
                                                   payload: data.payload));
  push-data(node.the-output, new-frame);
end;

define method push-data-aux (input :: <push-input>, node :: <dot1q-decapsulator>, data :: <ethernet-frame>);
  let new-frame = ethernet-frame(source-address: data.source-address,
                                 destination-address: data.destination-address,
                                 type-code: data.payload.type-code,
                                 payload: data.payload.payload);
  push-data(node.the-output, new-frame);
end;

define method create-socket (lower :: <vlan-layer>, #rest rest, #key filter-string, #all-keys)
 => (res :: <socket>)
  let input = create-input(lower.fan-in);
  let output = create-output-for-filter(lower.demultiplexer, filter-string | "ethernet");
  make(<input-output-socket>, owner: lower, input: input, output: output);
end;

define method check-socket-arguments? (lower :: <vlan-layer>, #rest rest, #key type, #all-keys)
 => (valid-arguments? :: <boolean>)
  //XXX: if (valid-type?)
  type == <ethernet-frame>
end;
define method check-upper-layer? (lower :: <vlan-layer>, upper :: <layer>) => (allowed? :: <boolean>);
  #t;
end;

define method check-lower-layer? (upper :: <vlan-layer>, lower :: <layer>) => (allowed? :: <boolean>);
  (~ upper.lower-socket) & check-socket-arguments?(lower, type: <ethernet-frame>)
end;

define method register-upper-layer (lower :: <vlan-layer>, upper :: <layer>)

end;

define method register-lower-layer (upper :: <vlan-layer>, lower :: <layer>)
  let ethernet-socket
    = create-socket(lower, type: <ethernet-frame>,
                    filter-string: format-to-string("(vlan-tag) & (vlan-tag.vlan-id = %d)", upper.@vlan-id));
  connect(ethernet-socket.socket-output, upper.dot1q-decapsulator);
  connect(upper.dot1q-encapsulator, ethernet-socket.socket-input);
  upper.lower-socket := ethernet-socket;
  register-property-changed-event(lower,
                                  #"running-state",
                                  method(x)
                                      upper.@running-state := x.property-changed-event-property.property-value
                                  end,
                                  owner: upper);
end;

define method deregister-lower-layer (upper :: <vlan-layer>, lower :: <layer>)
  close-socket(upper.lower-socket);
  upper.lower-socket := #f;
end;

