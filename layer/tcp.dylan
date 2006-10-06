module: layer

define open generic connection-tracking (l :: <tcp-layer>) => (res :: <vector-table>);

define class <tcp-layer> (<layer>)
  constant slot ip-layer :: <ip-layer>, required-init-keyword: ip-layer:;
  constant slot connection-tracking :: <vector-table> = make(<vector-table>);
  slot default-ip-address :: <ipv4-address>, init-keyword: default-ip-address:;
  slot ip-send-socket :: <ip-socket>;
end;

define inline method generate-id (tcp-frame :: <tcp-frame>) => (res :: <vector>)
  generate-id-aux (tcp-frame.parent.source-address,
                   tcp-frame.source-port,
                   tcp-frame.parent.destination-address,
                   tcp-frame.destination-port);
end;

define inline function generate-id-aux (source :: <ipv4-address>, source-port :: <integer>,
                                        destination :: <ipv4-address>, destination-port :: <integer>)
 => (res :: <vector>)
  concatenate(source.data,
              assemble-frame-as(<2byte-big-endian-unsigned-integer>, source-port),
              destination.data,
              assemble-frame-as(<2byte-big-endian-unsigned-integer>, destination-port));
end;
define method initialize (layer :: <tcp-layer>,
                          #rest rest, #key, #all-keys)
  let socket = create-socket(layer.ip-layer, 6);
  let cls-node = make(<closure-node>,
                      closure: method(x)
                                 let id = generate-id(x);
                                 let connection = element(layer.connection-tracking, id, default: #f);
                                 if (connection)
                                   process-data(connection, x);
                                 elseif (x.syn = 1)
                                   let socket = find-listener-socket(layer.sockets, x.destination-port);
                                   if (socket)
                                     let connection = make(<tcp-connection>,
                                                           socket: layer.ip-send-socket,
                                                           acknowledgment-number: $transform-from-bv(x.sequence-number),
                                                           source-port: x.source-port,
                                                           destination-port: x.destination-port,
                                                           source-address: x.parent.source-address,
                                                           destination-address: x.parent.destination-address);
                                     layer.connection-tracking[id] := connection;
                                     passive-open(connection);
                                     with-lock (socket.lock)
                                       add!(socket.connections, connection);
                                     end;
                                     process-data(connection, x);
                                   else
                                     format-out("Got a SYN to port %d, but found no listener, may send a RST\n",
                                                x.destination-port);
                                   end;
                                 else
                                   format-out("Packet for unknown connection received\n");
                                 end;
                               end);
                                 
  connect(socket.decapsulator, cls-node);
  layer.ip-send-socket := socket;
end;

define generic send-buffer (c :: <tcp-connection>) => (res);
define generic receive-buffer (c :: <tcp-connection>) => (res);
define generic tcp-sequence-number (c :: <tcp-connection>) => (res :: <float>);
define generic tcp-sequence-number-setter (value :: <float>, c :: <tcp-connection>) => (res :: <float>);
define generic tcp-acknowledgement-number (c :: <tcp-connection>) => (res :: <float>);
define generic tcp-acknowledgement-number-setter (value :: <float>, c :: <tcp-connection>) => (res :: <float>);
define generic tcp-window-size (c :: <tcp-connection>) => (res :: <integer>);
define generic tcp-window-size-setter (value :: <integer>, c :: <tcp-connection>) => (res :: <integer>);
define generic tcp-source-port (c :: <tcp-connection>) => (res :: <integer>);
define generic tcp-destination-port (c :: <tcp-connection>) => (res :: <integer>);
define generic tcp-source-address (c :: <tcp-connection>) => (res :: <ipv4-address>);
define generic tcp-destination-address (c :: <tcp-connection>) => (res :: <ipv4-address>);
define class <tcp-connection> (<filter>, <tcp-dingens>);
  constant slot send-buffer = make(<deque>);
  constant slot receive-buffer = make(<deque>);
  slot send-socket :: <socket>, required-init-keyword: socket:;
  slot tcp-sequence-number :: <float> = as(<float>, random(2 ^ 16)), init-keyword: sequence-number:;
  slot tcp-acknowledgement-number :: <float> = 0.0s0, init-keyword: acknowledgement-number:;
  slot tcp-window-size :: <integer> = 1500, init-keyword: window-size:;
  constant slot tcp-source-port :: <integer>, required-init-keyword: source-port:;
  constant slot tcp-destination-port :: <integer>, required-init-keyword: destination-port:;
  constant slot tcp-source-address :: <ipv4-address>, required-init-keyword: source-address:;
  constant slot tcp-destination-address :: <ipv4-address>, required-init-keyword: destination-address:;
end;

define method generate-id (tcp :: <tcp-connection>) => (res :: <vector>)
  generate-id-aux(tcp.tcp-destination-address, tcp.tcp-destination-port,
                  tcp.tcp-source-address, tcp.tcp-source-port);
end;

define constant $transform-from-bv = compose(byte-vector-to-float-be, data);
define constant $transform-to-bv = compose(big-endian-unsigned-integer-4byte, float-to-byte-vector-be);
define method send-via-tcp (conn :: <tcp-connection>,
                            #key ack, fin, rst, syn, urg, psh, data)
  let payload = make(<stretchy-byte-vector-subsequence>);
  if (data & instance?(conn.state, <established>))
    for (i from 0 below min(conn.tcp-window-size, data.size))
      payload[i] := data[i];
    end;
  end;
  let tcp-frame = make(<tcp-frame>,
                       source-port: conn.tcp-source-port,
                       destination-port: conn.tcp-destination-port,
                       sequence-number: $transform-to-bv(conn.tcp-sequence-number),
                       acknowledgement-number: $transform-to-bv(if (ack) conn.tcp-acknowledgement-number else 0.0s0 end),
                       urg: if (urg) 1 else 0 end,
                       ack: if (ack) 1 else 0 end,
                       psh: if (psh) 1 else 0 end,
                       rst: if (rst) 1 else 0 end,
                       syn: if (syn) 1 else 0 end,
                       fin: if (fin) 1 else 0 end,
                       window: 1500 - conn.receive-buffer.size,
                       payload: make(<raw-frame>, data: payload),
                       options-and-padding: make(<raw-frame>, data: make(<stretchy-byte-vector-subsequence>)));
  if (syn | fin)
    conn.tcp-sequence-number := conn.tcp-sequence-number + 1;
  end;
  if (data)
    conn.tcp-sequence-number := conn.tcp-sequence-number + payload.size;
  end;
  send(conn.send-socket, conn.tcp-destination-address, tcp-frame);
end;

define method read-element (tcp-connection :: <tcp-connection>) => (res :: false-or(<byte>))
  if (tcp-connection.receive-buffer.size > 0)
    pop(tcp-connection.receive-buffer)
  end;
end;

define method read (tcp-connection :: <tcp-connection>) => (res :: <collection>)
  let res = make(<stretchy-vector>);
  block(ret)
    while(#t)
      let ele = read-element(tcp-connection);
      if (ele)
        res := add!(res, ele);
      else
        ret();
      end;
    end;
  end;
  res;
end;

define method write-element (tcp-connection :: <tcp-connection>, data :: <byte>)
  push-last(tcp-connection.send-buffer, data);
end;
define method write-element (tcp-connection :: <tcp-connection>, data :: <character>)
  write-element(tcp-connection, as(<byte>, data));
end;

define method write (tcp-connection :: <tcp-connection>, data :: <string>)
  write(tcp-connection, map-as(<vector>, curry(as, <byte>), data));
end;

define method write (tcp-connection :: <tcp-connection>, data :: <sequence>)
  do(curry(write-element, tcp-connection), data);
  send-via-tcp(tcp-connection, data: data, ack: #t);
end;

define method process-data (connection :: <tcp-connection>, packet :: <tcp-frame>)
  if ((connection.tcp-acknowledgement-number = 0) | ($transform-from-bv(packet.sequence-number) = connection.tcp-acknowledgement-number))
    if (packet.syn = 1)
      connection.tcp-acknowledgement-number := $transform-from-bv(packet.sequence-number) + 1;
      if (packet.ack = 1)
        syn-ack-received(connection);
      else
        syn-received(connection);
      end;
    elseif (packet.fin = 1)
      connection.tcp-acknowledgement-number := connection.tcp-acknowledgement-number + 1;
      if (packet.ack = 1)
        fin-ack-received(connection);
      else
        fin-received(connection);
      end;
    elseif (packet.ack = 1)
      connection.tcp-window-size := packet.window;
      for (i from connection.tcp-sequence-number - connection.send-buffer.size below $transform-from-bv(packet.acknowledgement-number))
        pop(connection.send-buffer);
      end;
      connection.tcp-acknowledgement-number := connection.tcp-acknowledgement-number + byte-offset(frame-size(packet.payload));
      ack-received(connection);
    elseif (packet.rst = 1)
      rst-received(connection);
    else
      format-out("Unknown flag combination\n");
    end;
    if (instance?(connection.state, <established>))
      do(curry(push-last, connection.receive-buffer), packet.payload.data)
    end;
  end;
end;

define method syn-received (tcp-connection :: <tcp-connection>) => (res :: <tcp-state>)
  let new-state = syn-received(tcp-connection.state);
  if (new-state ~= tcp-connection.state)
    send-via-tcp(tcp-connection, syn: #t, ack: #t);
    tcp-connection.state := new-state;
  end;
end;

define method syn-ack-received (tcp-connection :: <tcp-connection>) => (res :: <tcp-state>)
  let new-state = syn-ack-received(tcp-connection.state);
  if (new-state ~= tcp-connection.state)
    send-via-tcp(tcp-connection, ack: #t);
    tcp-connection.state := new-state;
  end;
  tcp-connection.state
end;

define method fin-ack-received (tcp-connection :: <tcp-connection>) => (res :: <tcp-state>)
  let new-state = fin-ack-received(tcp-connection.state);
  if (new-state ~= tcp-connection.state)
    send-via-tcp(tcp-connection, ack: #t);
    tcp-connection.state := new-state;
  end;
  tcp-connection.state
end;

define method fin-received (tcp-connection :: <tcp-connection>) => (res :: <tcp-state>)
  let new-state = fin-received(tcp-connection.state);
  if (new-state ~= tcp-connection.state)
    send-via-tcp(tcp-connection, ack: #t);
    tcp-connection.state := new-state;
  end;    
  tcp-connection.state
end;

define method ack-received (tcp-connection :: <tcp-connection>) => (res :: <tcp-state>)
  let new-state = ack-received(tcp-connection.state);
  if (new-state ~= tcp-connection.state)
    tcp-connection.state := new-state;
  end;
  tcp-connection.state
end;

define method rst-received (tcp-connection :: <tcp-connection>) => (res :: <tcp-state>)
  //NYI
end;

define method passive-open (tcp-connection :: <tcp-connection>) => (res :: <tcp-state>)
  tcp-connection.state := passive-open(tcp-connection.state);
end;

define method active-open (tcp-connection :: <tcp-connection>) => (res :: <tcp-state>)
  send-via-tcp(tcp-connection, syn: #t);
  tcp-connection.state := active-open(tcp-connection.state);
end;

define method close (tcp-connection :: <tcp-connection>) => (res :: <tcp-state>)
  send-via-tcp(tcp-connection, fin: #t);
  tcp-connection.state := close(tcp-connection.state);
end;

define open generic listen-port (t :: <tcp-listener-socket>) => (res :: <integer>);
define open generic connections (t :: <tcp-listener-socket>) => (res :: <stretchy-vector>);

define class <tcp-listener-socket> (<socket>)
  constant slot listen-port :: <integer>, required-init-keyword: listen-port:;
  constant slot listen-address :: <ipv4-address>, required-init-keyword: listen-address:;
  constant slot connections :: <stretchy-vector> = make(<stretchy-vector>);
  constant slot lock :: <lock> = make(<lock>);
end;

define method create-server-socket (layer :: <tcp-layer>,
                                    listen-port :: <integer>,
                                    #key listen-address :: <ipv4-address>);
  let socket = make(<tcp-listener-socket>,
                    listen-port: listen-port,
                    listen-address: listen-address | layer.default-ip-address);
  add!(layer.sockets, socket);
end;

define method accept (socket :: <tcp-listener-socket>) => (res :: false-or(<tcp-connection>));
  with-lock (socket.lock)
    if (socket.connections.size > 0)
      let conn = socket.connections[0];
      remove!(socket.connections, conn);
      conn;
    end;
  end;
end;
define method create-client-socket (layer :: <tcp-layer>,
                                    destination-address :: <ipv4-address>,
                                    destination-port :: <integer>,
                                    #key source-port :: false-or(<integer>),
                                    source-address :: false-or(<ipv4-address>));
  let listen-port = source-port | random(2 ^ 16);
  let listen-address = source-address | layer.default-ip-address;
  let connection = make(<tcp-connection>,
                        socket: layer.ip-send-socket,
                        source-port: listen-port,
                        destination-port: destination-port,
                        destination-address: destination-address,
                        source-address: listen-address);
  let id = generate-id(connection);
  layer.connection-tracking[id] := connection;
  active-open(connection);
  sleep(2);
  connection;
end;

define method find-listener-socket (sockets, destination-port)
  block(ret)
    for (ele in sockets)
      if (ele.listen-port = destination-port)
        ret(ele)
      end;
    end;
  end;
end;


begin
  let ip-layer = init-ethernet();
  let tcp = make(<tcp-layer>, ip-layer: ip-layer, default-ip-address: ip-layer.default-ip-address);
  let s = create-client-socket(tcp, ipv4-address("213.73.91.29"), 80);
  write(s, "GET / HTTP/1.1\r\nHost: www.ccc.de\r\n\r\n");
  while(#t)
    let res = read(s);
    if (res & res.size > 0)
      format-out("Read %=\n", res)
    end;
  end;
end;
