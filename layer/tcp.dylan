module: layer

define open generic connection-tracking (l :: <tcp-layer>) => (res :: <vector-table>);
define open generic notification (t) => (res :: <notification>);
define open generic notification-setter (value :: <notification>, t) => (res :: <notification>);


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
                          #next next-method, #rest rest, #key, #all-keys)
  next-method();
  let socket = create-socket(layer.ip-layer, 6);
  let cls-node
    = make(<closure-node>,
           closure: method(x)
                        let id = generate-id(x);
                        let connection
                          = element(layer.connection-tracking, id, default: #f);
                        if (connection)
                          process-data(connection, x);
                        elseif (x.syn = 1)
                          let socket
                            = find-listener-socket(layer.sockets, x.destination-port);
                          if (socket)
                            let connection
                              = make(<tcp-connection>,
                                     tcp-layer: layer,
                                     acknowledgement-number: $transform-from-bv(x.sequence-number),
                                     source-port: x.destination-port,
                                     destination-port: x.source-port,
                                     source-address: x.parent.destination-address,
                                     destination-address: x.parent.source-address);
                            layer.connection-tracking[id] := connection;
                            passive-open(connection);
                            with-lock (socket.listener-lock)
                              push-last(socket.connections, connection);
                              release(socket.notification);
                            end;
                            process-data(connection, x);
                          else
                            let ack = $transform-from-bv(x.sequence-number);
                            send(layer.ip-send-socket,
                                 x.parent.source-address,
                                 make(<tcp-frame>,
                                      source-port: x.destination-port,
                                      destination-port: x.source-port,
                                      ack: 1, rst: 1,
                                      acknowledgement-number: $transform-to-bv(ack + 1),
                                      sequence-number: $transform-to-bv(0.0s0)));
                          end;
                        else
                          let ack = $transform-from-bv(x.sequence-number);
                          send(layer.ip-send-socket,
                               x.parent.source-address,
                               make(<tcp-frame>,
                                    source-port: x.destination-port,
                                    destination-port: x.source-port,
                                    ack: 1, rst: 1,
                                    acknowledgement-number: $transform-to-bv(ack + 1),
                                    sequence-number: $transform-to-bv(0.0s0)));
                        end;
                    end);

  connect(socket.decapsulator, cls-node);
  layer.ip-send-socket := socket;
end;

define generic send-buffer (c :: <tcp-connection>) => (res);
define generic receive-buffer (c :: <tcp-connection>) => (res);
define generic tcp-sequence-number (c :: <tcp-connection>) => (res :: <float>);
define generic tcp-sequence-number-setter (value :: <float>, c :: <tcp-connection>) => (res :: <float>);
define generic tcp-acknowledgement-number (c :: <tcp-connection>) => (res :: false-or(<float>));
define generic tcp-acknowledgement-number-setter (value :: false-or(<float>), c :: <tcp-connection>) => (res :: false-or(<float>));
define generic tcp-window-size (c :: <tcp-connection>) => (res :: <integer>);
define generic tcp-window-size-setter (value :: <integer>, c :: <tcp-connection>) => (res :: <integer>);
define generic tcp-source-port (c :: <tcp-connection>) => (res :: <integer>);
define generic tcp-destination-port (c :: <tcp-connection>) => (res :: <integer>);
define generic tcp-source-address (c :: <tcp-connection>) => (res :: <ipv4-address>);
define generic tcp-destination-address (c :: <tcp-connection>) => (res :: <ipv4-address>);
define generic tcp-layer (c :: <tcp-connection>) => (res :: <tcp-layer>);
define generic last-received-packet (c :: <tcp-connection>) => (res :: <tcp-frame>);
define generic last-received-packet-setter (value :: <tcp-frame>, c :: <tcp-connection>) => (res :: <tcp-frame>);
define generic established-notification (c :: <tcp-connection>) => (res :: <notification>);
define generic established-notification-setter (value :: <notification>, c :: <tcp-connection>) => (res :: <notification>);
define class <tcp-connection> (<tcp-dingens>, <stream>)
  constant slot send-buffer = make(<deque>);
  constant slot receive-buffer = make(<deque>);
  constant slot tcp-layer :: <tcp-layer>, required-init-keyword: tcp-layer:;
  slot tcp-sequence-number :: <float> = as(<float>, random(2 ^ 16)), init-keyword: sequence-number:;
  slot tcp-acknowledgement-number :: false-or(<float>) = #f, init-keyword: acknowledgement-number:;
  slot tcp-window-size :: <integer> = 1500, init-keyword: window-size:;
  constant slot tcp-source-port :: <integer>, required-init-keyword: source-port:;
  constant slot tcp-destination-port :: <integer>, required-init-keyword: destination-port:;
  constant slot tcp-source-address :: <ipv4-address>, required-init-keyword: source-address:;
  constant slot tcp-destination-address :: <ipv4-address>, required-init-keyword: destination-address:;
  slot last-received-packet :: <tcp-frame>;
  slot notification :: <notification>;
  slot established-notification :: <notification>;
end;

define method initialize (tcp-connection :: <tcp-connection>,
                          #next next-method, #rest rest, #key, #all-keys)
  next-method();
  tcp-connection.notification := make(<notification>, lock: tcp-connection.lock);
  tcp-connection.established-notification := make(<notification>, lock: tcp-connection.lock);
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
  if (data & instance?(conn.state, type-union(<close-wait>, <established>)))
    for (i from 0 below min(conn.tcp-window-size, data.size))
      payload[i] := data[i];
    end;
  end;
  let tcp-frame = make(<tcp-frame>,
                       source-port: conn.tcp-source-port,
                       destination-port: conn.tcp-destination-port,
                       sequence-number: $transform-to-bv(conn.tcp-sequence-number),
                       acknowledgement-number: $transform-to-bv(if (ack) conn.tcp-acknowledgement-number else 0.0d0 end),
                       urg: if (urg) 1 else 0 end,
                       ack: if (ack) 1 else 0 end,
                       psh: if (psh) 1 else 0 end,
                       rst: if (rst) 1 else 0 end,
                       syn: if (syn) 1 else 0 end,
                       fin: if (fin) 1 else 0 end,
                       window: 65535 - conn.receive-buffer.size,
                       payload: make(<raw-frame>, data: payload));
  if (syn | fin)
    conn.tcp-sequence-number := conn.tcp-sequence-number + 1;
  end;
  if (data)
    conn.tcp-sequence-number := conn.tcp-sequence-number + payload.size;
  end;
  send(conn.tcp-layer.ip-send-socket, conn.tcp-destination-address, tcp-frame);
end;

define method read-element (tcp-connection :: <tcp-connection>, #key on-end-of-stream = $unsupplied)
  => (res)
  with-lock (tcp-connection.lock)
    block(ret)
      while (~ stream-input-available?(tcp-connection))
        if (instance?(tcp-connection.state, type-union(<close-wait>, <last-ack>, <closing>, <time-wait>, <closed>)))
          if (on-end-of-stream = $unsupplied)
            signal(make(<end-of-stream-error>, stream: tcp-connection));
          else
            ret(on-end-of-stream)
          end;
        else
          wait-for(tcp-connection.notification);
        end;
      end;
      pop(tcp-connection.receive-buffer)
    end;
  end;
end;

define method stream-input-available? (tcp :: <tcp-connection>) => (res :: <boolean>)
  tcp.receive-buffer.size > 0;
end;
define method read (tcp-connection :: <tcp-connection>, n :: <integer>, #key on-end-of-stream = $unsupplied) => (res)
  let res = make(<stretchy-vector>);
  block(ret)
    for (i from 0 below n)
      let ele = read-element(tcp-connection, on-end-of-stream: #f);
      if (ele)
        res := add!(res, ele);
      elseif (on-end-of-stream = $unsupplied)
        signal(make(<incomplete-read-error>, stream: tcp-connection, sequence: res, count: n)) 
      else
        ret(on-end-of-stream)
      end;
    end;
    res;
  end;
end;

define method write-element (tcp-connection :: <tcp-connection>, data :: <byte>) => ()
  with-lock (tcp-connection.lock)
    if (instance?(tcp-connection.state, type-union(<established>, <close-wait>)))
      push-last(tcp-connection.send-buffer, data);
    else
      error("Stream closed for writing")
    end;
  end;
end;
define method write-element (tcp-connection :: <tcp-connection>, data :: <character>) => ()
  write-element(tcp-connection, as(<byte>, data));
end;

define method write (tcp-connection :: <tcp-connection>, data :: <string>, #key start, end: last) => ()
  write(tcp-connection, map-as(<vector>, curry(as, <byte>), data));
end;

define method write (tcp-connection :: <tcp-connection>, data :: <sequence>, #key start, end: last) => ()
  do(curry(write-element, tcp-connection), data);
  with-lock (tcp-connection.lock)
    send-via-tcp(tcp-connection, data: data, ack: #t);
  end;
end;

define method process-data (connection :: <tcp-connection>, packet :: <tcp-frame>)
  with-lock (connection.lock)
    if ((~ connection.tcp-acknowledgement-number)
        | ($transform-from-bv(packet.sequence-number) = connection.tcp-acknowledgement-number))
      let last-ack = (connection.tcp-sequence-number = $transform-from-bv(packet.acknowledgement-number));
      let event =
        case
          (packet.rst = 1) => #"rst-received";
          ((packet.ack = 1) & (packet.syn = 0) & (packet.fin = 0) & (~ last-ack)) => #"ack-received";
          ((packet.ack = 1) & (packet.syn = 0) & (packet.fin = 0) & last-ack) => #"last-ack-received";
          ((packet.ack = 1) & (packet.syn = 0) & (packet.fin = 1) & last-ack) => #"fin-ack-received";
          ((packet.ack = 1) & (packet.syn = 1) & (packet.fin = 0)) => #"syn-ack-received";
          ((packet.ack = 0) & (packet.syn = 1) & (packet.fin = 0)) => #"syn-received";
          ((packet.syn = 0) & (packet.fin = 1)) => #"fin-received";
          otherwise => #f;
        end;
      if (event)
        connection.last-received-packet := packet;
        process-event(connection, event);
      else
        format-out("Unknown flag combination\n")
      end;
    end;
  end;
end;

define macro transition-definer
  {
    define transition (?old:expression => ?new:name)
      ?:body
    end
  } => {
    define method state-transition (?=tcp-connection :: <tcp-connection>,
                                    ?=old-state :: ?old,
                                    ?=new-state :: ?new,
                                    #next next-method) => ();
      let ?=send = curry(send-via-tcp, ?=tcp-connection);
      ?body;
      next-method();
    end
  }
end;

define transition (<tcp-state> => <established>)
  release(tcp-connection.established-notification)
end;

define transition (<established> => <established>)
  let packet = tcp-connection.last-received-packet;
  let acknowledge = $transform-from-bv(packet.acknowledgement-number);
  if (tcp-connection.tcp-sequence-number <= acknowledge)
    tcp-connection.tcp-window-size := tcp-connection.last-received-packet.window;
    for (i from tcp-connection.tcp-sequence-number - tcp-connection.send-buffer.size below acknowledge)
      pop(tcp-connection.send-buffer);
    end;
    if (frame-size(packet.payload) > 0)
      receive-data(tcp-connection);
      send(ack: #t);
    end;
  end;
end;

define inline function receive-data (tcp-connection :: <tcp-connection>)
  let packet = tcp-connection.last-received-packet;
  do(curry(push-last, tcp-connection.receive-buffer), packet.payload.data);
  tcp-connection.tcp-acknowledgement-number
    := tcp-connection.tcp-acknowledgement-number + byte-offset(frame-size(packet.payload));
  release(tcp-connection.notification);
end;
define transition (<listen> => <syn-received>)
  tcp-connection.tcp-acknowledgement-number
    := $transform-from-bv(tcp-connection.last-received-packet.sequence-number) + 1;
  send(syn: #t, ack: #t)
end;

define transition (<syn-sent> => <established>)
  tcp-connection.tcp-acknowledgement-number
    := $transform-from-bv(tcp-connection.last-received-packet.sequence-number) + 1;
  send(ack: #t)
end;

define transition (<syn-sent> => <syn-received>)
  tcp-connection.tcp-acknowledgement-number
    := $transform-from-bv(tcp-connection.last-received-packet.sequence-number) + 1;
  send(syn: #t, ack: #t)
end;

define transition (<established> => <close-wait>)
  if (frame-size(tcp-connection.last-received-packet.payload) > 0)
    receive-data(tcp-connection);
  end;
  tcp-connection.tcp-acknowledgement-number := tcp-connection.tcp-acknowledgement-number + 1;
  send(ack: #t);
  release(tcp-connection.notification)
end;

define transition (<close-wait> => <last-ack>)
  send(fin: #t, ack: #t)  // theory says no ack, but in practice it's required
end;

define transition (<established> => <fin-wait1>)
  send(fin: #t, ack: #t)  // theory says no ack, but in practice it's required
end;

define transition (<fin-wait1> => <closing>)
  if (frame-size(tcp-connection.last-received-packet.payload) > 0)
    receive-data(tcp-connection);
  end;
  tcp-connection.tcp-acknowledgement-number := tcp-connection.tcp-acknowledgement-number + 1;
  send(ack: #t);
  release(tcp-connection.notification)
end;

define transition (<fin-wait1> => <fin-wait1>)
  if (frame-size(tcp-connection.last-received-packet.payload) > 0)
    receive-data(tcp-connection);
    send(ack: #t);
  end;
end;

define transition (<fin-wait2> => <fin-wait2>)
  if (frame-size(tcp-connection.last-received-packet.payload) > 0)
    receive-data(tcp-connection);
    send(ack: #t);
  end;
end;

define transition (type-union(<fin-wait1>, <fin-wait2>) => <time-wait>)
  if (frame-size(tcp-connection.last-received-packet.payload) > 0)
    receive-data(tcp-connection);
  end;
  tcp-connection.tcp-acknowledgement-number := tcp-connection.tcp-acknowledgement-number + 1;
  send(ack: #t);
  release(tcp-connection.notification)
end;

define transition (<tcp-state> => <time-wait>)
  make(<timer>, in: 30 * 2, event: curry(process-event-locked, tcp-connection, #"2msl-timeout"));
end;

define transition (<syn-received> => <fin-wait1>)
  send(fin: #t)
end;

define transition (<closed> => <syn-sent>)
  send(syn: #t)
end;

define transition (<tcp-state> => <closed>)
  release(tcp-connection.notification);
  release(tcp-connection.established-notification);
  remove-key!(tcp-connection.tcp-layer.connection-tracking, tcp-connection.generate-id);
end;

define method process-event-locked (tcp-connection :: <tcp-connection>, event) => ()
  with-lock (tcp-connection.lock)
    process-event(tcp-connection, event)
  end;
end;

define method passive-open (tcp-connection :: <tcp-connection>)
  process-event-locked(tcp-connection, #"passive-open")
end;

define method active-open (tcp-connection :: <tcp-connection>)
  process-event-locked(tcp-connection, #"active-open");
end;

define method close (tcp-connection :: <tcp-connection>, #key) => ()
  process-event-locked(tcp-connection, #"close")
end;

define open generic listen-port (t :: <object>) => (res :: <integer>);
define open generic connections (t :: <tcp-listener-socket>) => (res :: <deque>);
define open generic listener-lock (t :: <tcp-listener-socket>) => (res :: <lock>);


define class <tcp-listener-socket> (<object>)
  constant slot listen-port :: <integer>, required-init-keyword: listen-port:;
  constant slot listen-address :: <ipv4-address>, required-init-keyword: listen-address:;
  constant slot connections :: <deque> = make(<deque>);
  constant slot listener-lock :: <lock> = make(<lock>);
  slot notification :: <notification>;
end;

define method initialize (socket :: <tcp-listener-socket>,
                          #rest rest, #key, #all-keys)
  next-method();
  socket.notification := make(<notification>, lock: socket.listener-lock);
end;

define method create-server-socket (layer :: <tcp-layer>,
                                    listen-port :: <integer>,
                                    #key listen-address :: false-or(<ipv4-address>));
  let socket = make(<tcp-listener-socket>,
                    listen-port: listen-port,
                    listen-address: listen-address | layer.default-ip-address);
  add!(layer.sockets, socket);
  socket;
end;

define method accept (socket :: <tcp-listener-socket>) => (res :: false-or(<tcp-connection>));
  with-lock (socket.listener-lock)
    while (socket.connections.size = 0)
      wait-for(socket.notification);
    end;
    let connection = pop(socket.connections);
    with-lock (connection.lock)
      wait-for(connection.established-notification); //XXX timeout!
    end;
    connection;
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
                        tcp-layer: layer,
                        source-port: listen-port,
                        destination-port: destination-port,
                        destination-address: destination-address,
                        source-address: listen-address);
  let id = generate-id(connection);
  layer.connection-tracking[id] := connection;
  active-open(connection);
  with-lock (connection.lock)
    wait-for(connection.established-notification); //XXX: timeout
    if (instance?(connection.state, <established>))
      connection;
    else
      #f
    end;
  end;
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



