module: socket-flow
synopsis: 
author: 
copyright: 

define class <flow-socket> (<filter>)
  slot running? :: <boolean> = #t;
  slot unix-file-descriptor :: <integer>;
  constant slot port :: <integer>,
    required-init-keyword: port:;
  constant slot frame-type :: subclass(<container-frame>),
    required-init-keyword: frame-type:;
  //maybe: address, protocol?
  slot reply-addr;
  slot reply-port;
end;

define method initialize
    (flow-socket :: <flow-socket>, #next next-method, #key port, #all-keys)
  => ()
  next-method();
  let packet-socket = socket($PF-INET, $SOCK-DGRAM, 0);
  flow-socket.unix-file-descriptor := packet-socket;
  if (packet-socket == -1)
    error("Error opening socket\n");
  else
    with-stack-structure (sockaddr :: <sockaddr-in*>)
      sockaddr.sin-family-value := $AF-INET;
      sockaddr.sin-port-value   := htons(port);
      sockaddr.sin-addr-value   := $INADDR-ANY;
      if (bind(packet-socket, sockaddr, size-of(<sockaddr-in>)) == -1)
        format-out("Couldn't bind\n");
      end if;
    end;
  end if;
end method initialize;

define method flow-socket-close (flow-socket :: <flow-socket>)
  close(flow-socket.unix-file-descriptor);
end;

define constant <buffer> = <byte-vector>;

define method flow-socket-receive (flow-socket :: <flow-socket>)
  => (buffer)
  let buffer = make(<buffer>, size: 512);
  local method unix-receive ()
          with-stack-structure (sockaddr :: <sockaddr-in*>)
            with-stack-structure (sockaddr-size :: <socklen-t*>)
              pointer-value(sockaddr-size) := size-of(<sockaddr-in>);
              let fd = flow-socket.unix-file-descriptor;
              let read-bytes =
                interruptible-system-call(unix-recv-buffer-from(fd,
                                                                buffer-offset(buffer, 0),
                                                                512,
                                                                0,
                                                                sockaddr,
                                                                sockaddr-size));
              if (read-bytes == -1)
                //Only want to catch $EINTR, but getting mps assertion failures
                //this is now done via interruptible-system-call macro
                #f;
              else
                flow-socket.reply-addr := sockaddr.sin-addr-value;
                flow-socket.reply-port := sockaddr.sin-port-value;
                copy-sequence(buffer, end: read-bytes);
              end if;
            end
          end
        end method;
  unix-receive();
end method flow-socket-receive;

define method push-data-aux
    (input :: <push-input>, node :: <flow-socket>, payload :: <container-frame>)
  with-stack-structure (sockaddr :: <sockaddr-in*>)
    sockaddr.sin-family-value := $AF-INET;
    sockaddr.sin-port-value   := node.reply-port;
    sockaddr.sin-addr-value   := node.reply-addr;
    let data = as(<byte-vector>, assemble-frame(payload).packet);
//    with-stack-structure (sockaddr-size :: <socklen-t*>)
//      pointer-value(sockaddr-size) := size-of(<sockaddr-in>);
      format-out("sending\n");
      for (x in data)
        format-out("%x ", x);
      end;
  format-out("\n");
      force-output(*standard-output*);
      unix-send-buffer-to(node.unix-file-descriptor,
                          buffer-offset(data, 0),
                          data.size,
                          0,
                          sockaddr,
                          size-of(<sockaddr-in>));
    end;
//  end;
end;

define function buffer-offset
    (the-buffer :: <buffer>, data-offset :: <integer>)
 => (result-offset :: <machine-word>)
  u%+(data-offset,
      primitive-wrap-machine-word
        (primitive-repeated-slot-as-raw
           (the-buffer, primitive-repeated-slot-offset(the-buffer))))
end function;

define method toplevel (s :: <flow-socket>)
  while (s.running?)
    let packet = flow-socket-receive(s);
    format-out("received a packet\n");
    for (x in packet)
      format-out("%x ", x);
    end;
    format-out("\n");
    force-output(*standard-output*);
    let parsed = parse-frame(s.frame-type, packet);
    format-out("received a packet %=\n", summary(parsed));
    force-output(*standard-output*);
    push-data(s.the-output, parsed);
  end;
  flow-socket-close(s);
end;

