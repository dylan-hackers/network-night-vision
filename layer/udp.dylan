module: layer

define class <udp-layer> (<layer>)
  inherited slot frame-type :: subclass(<container-frame>) = <udp-frame>;
  constant slot ip-layer :: <ip-layer>, required-init-keyword: ip-layer:;
  slot ip-send-socket :: <ip-socket>;
end;

define method initialize (layer :: <udp-layer>,
                          #next next-method, #rest rest, #key, #all-keys)
  next-method();
  let socket = create-socket(layer.ip-layer, 17);
  connect(socket.decapsulator, layer.demultiplexer);
  layer.ip-send-socket := socket;
end;

define class <udp-socket> (<socket>)
  constant slot udp-layer :: <udp-layer>, required-init-keyword: layer:;
  constant slot server-port :: <integer>, required-init-keyword: server-port:;
  constant slot client-port :: <integer>, required-init-keyword: client-port:;
  constant slot client-address :: false-or(<ipv4-address>), init-keyword: client-address:;
  constant slot server-address :: false-or(<ipv4-address>), init-keyword: server-address:;
end;

define method create-socket (layer :: <udp-layer>,
                             server-port :: <integer>,
                             #key client-port,
                                  client-address,
                                  server-address)
 => (socket :: <udp-socket>)
  let cport = client-port | random(2 ^ 16 - 1);
  let socket = make(<udp-socket>,
                    client-port: cport,
                    server-port: server-port,
                    client-address: client-address,
                    server-address: server-address,
                    layer: layer);
  socket.demultiplexer-output
    := create-output-for-filter(layer.demultiplexer,
                                format-to-string("udp.destination-port = %d", cport));
  connect(socket.demultiplexer-output, socket.decapsulator);
  socket;
end;

define method send (socket :: <udp-socket>,
                    destination :: <ipv4-address>,
                    payload :: <container-frame>);
  let udp = make(<udp-frame>,
                 payload: payload,
                 source-port: socket.client-port,
                 destination-port: socket.server-port);
  send(socket.udp-layer.ip-send-socket, destination, udp);
end;

define function build-udp-layer (ip-layer :: <ip-layer>)
  make(<udp-layer>, ip-layer: ip-layer)
end;

define function udp-begin()
  let ethernet-layer
    = build-ethernet-layer("eth0", promiscuous?: #t);
  let ethernet-socket = create-raw-socket(ethernet-layer);
  let (ip-layer, adapter)
    = build-ip-layer(ethernet-layer,
                     ip-address: ipv4-address("23.23.23.112"),
                     default-gateway: ipv4-address("23.23.23.1"),
                     netmask: 24);

  let bittorrent-frame = make(<bittorrent-announce>,
                              event: big-endian-unsigned-integer-4byte(#(0, 0, 0, 2)));
  let udpframe = make(<udp-frame>,
                       source-port: 2342,
                       destination-port: 6969,
                       payload: bittorrent-frame);
  format-out("sending %=\n", udpframe);
  send(ip-layer, ipv4-address("217.13.206.133"), udpframe);

  let ff = make(<frame-filter>, frame-filter: "udp.source-port = 6969");
  connect(ethernet-socket, ff);
  connect(ff, make(<verbose-printer>,
                   stream: *standard-output*));
  sleep(100);
end;

//udp-begin();
