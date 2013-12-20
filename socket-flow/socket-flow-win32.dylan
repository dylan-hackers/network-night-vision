module: socket-flow
synopsis: 
author: 
copyright: 

define method initialize
    (flow-socket :: <flow-socket>, #next next-method, #key port, #all-keys)
  => ()
  next-method();
  start-sockets();
  let packet-socket = socket($PF-INET, $SOCK-DGRAM, 0);
  flow-socket.unix-file-descriptor := packet-socket;
  if (packet-socket == $INVALID-SOCKET)
    error("Error opening socket\n");
  else
    with-stack-structure (sockaddr :: <LPSOCKADDR-IN>)
      sockaddr.sin-family-value := $AF-INET;
      sockaddr.sin-port-value   := htons(port);
      sockaddr.sin-addr-value   := as(<machine-word>, $INADDR-ANY);
      if (bind(packet-socket, sockaddr, size-of(<sockaddr-in>)) == $SOCKET-ERROR)
        error("Couldn't bind\n");
      end if;
    end;
  end if;
end method initialize;

define method flow-socket-close (flow-socket :: <flow-socket>)
  closesocket(flow-socket.unix-file-descriptor);
end;

define method flow-socket-receive (flow-socket :: <flow-socket>)
  => (buffer)
  let buffer = make(<buffer>, size: 512);
  local method unix-receive ()
          with-stack-structure (sockaddr :: <lpsockaddr-in>)
            with-stack-structure (sockaddr-size :: <C-int*>)
              pointer-value(sockaddr-size) := size-of(<sockaddr-in>);
              let fd = flow-socket.unix-file-descriptor;
              let read-bytes =
                win32-recv-buffer-from(fd,
                                       byte-storage-address(buffer),
                                       512,
                                       0,
                                       sockaddr,
                                       sockaddr-size);
              if (read-bytes == $SOCKET-ERROR)
                error("win32-recv-buffer-from returned socket-error");
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

define constant <sin*> = <lpsockaddr-in>;
define constant msendto = win32-send-buffer-to;
