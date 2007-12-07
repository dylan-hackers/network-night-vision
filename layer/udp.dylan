module: layer

define class <udp-layer> (<layer>)
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
  let ip-layer = init-ip-layer();
  let udp = make(<udp-layer>, ip-layer: ip-layer);
  let socket = create-socket(udp, 53);
  connect(socket.decapsulator, make(<verbose-printer>, stream: *standard-output*));
  send(udp.ip-send-socket, 
       ipv4-address("141.1.1.1"),
       make(<udp-frame>, source-port: 53, destination-port: 53,
            payload: make(<dns-frame>,
                          questions: vector(make(<dns-question>,
                                                 question-type:  1, // A
                                                 question-class: 1, // THE INTERNET
                                                 domainname: as(<domain-name>, "www.ccc.de"))))));
  sleep(10000);
/*
  let tcp = make(<tcp-layer>, ip-layer: ip-layer, default-ip-address: ip-layer.default-ip-address);
  let s = create-client-socket(tcp, ipv4-address("213.73.91.29"), 80);
  write(s, "GET / HTTP/1.1\r\nHost: www.ccc.de\r\nConnection: keep-alive\r\n\r\n");
  block(ret)
    while (#t)
      let res = read(s, 20, on-end-of-stream: #f);
      //if (res)
        //format-out("Read %s\n", map-as(<string>, curry(as, <character>), res))
      //else
        close(s);
        ret();
      //end;
    end;
  end;
  let ss = create-server-socket(tcp, 23);
  while (#t)
    let conn = accept(ss);
    write(conn, "fnord");
    close(conn);
  end;
  sleep(1000);
*/
end;

//udp-begin();
