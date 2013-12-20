module: socket-flow
synopsis: 
author: 
copyright: 

define class <flow-socket> (<filter>)
  slot running? :: <boolean> = #t;
  slot unix-file-descriptor; //<integer> on UNIX, <machine-word> on Windows
  constant slot port :: <integer>,
    required-init-keyword: port:;
  constant slot frame-type :: subclass(<container-frame>),
    required-init-keyword: frame-type:;
  //maybe: address, protocol?
  slot reply-addr;
  slot reply-port;
end;

define constant <buffer> = <byte-vector>;

define method push-data-aux
    (input :: <push-input>, node :: <flow-socket>, payload :: <container-frame>)
  with-stack-structure (sockaddr :: <sin*>)
    sockaddr.sin-family-value := $AF-INET;
    sockaddr.sin-port-value   := node.reply-port;
    sockaddr.sin-addr-value   := node.reply-addr;
    let data = as(<byte-vector>, assemble-frame(payload).packet);
    msendto(node.unix-file-descriptor,
            byte-storage-address(data),
            data.size,
            0,
            sockaddr,
            size-of(<sockaddr-in>));
  end;
end;

define method toplevel (s :: <flow-socket>)
  while (s.running?)
    let packet = flow-socket-receive(s);
    let parsed = parse-frame(s.frame-type, packet);
    push-data(s.the-output, parsed);
  end;
  flow-socket-close(s);
end;
