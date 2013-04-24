module: socket-flow
synopsis: 
author: 
copyright: 

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
        error("Couldn't bind");
      end if;
    end;
  end if;
end method initialize;

define method flow-socket-close (flow-socket :: <flow-socket>)
  close(flow-socket.unix-file-descriptor);
end;

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

define constant <sin*> = <sockaddr-in*>;
define constant msendto = unix-send-buffer-to;
