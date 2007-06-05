module: interfaces
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define constant $ethernet-buffer-size :: <integer> = 1548;
define constant <buffer> = <byte-vector>;

define class <interface> (<object>)
  constant slot name :: <string>,
    required-init-keyword: name:;
  slot unix-file-descriptor :: <integer> = 23;
end class;

define function name-to-index (socket, name)
  with-stack-structure (ifreq :: <ifreq*>)
    ifreq.ifr-name := name;
    let rc = ioctl(socket, $SIOCGIFINDEX, ifreq);
    if (rc == -1)
      error("Error binding to interface %s\n", name);
    end if;
    ifreq.ifr-ifindex;
  end with-stack-structure;
end function name-to-index;

define sealed domain initialize (<interface>);

define method initialize
    (interface :: <interface>, #next next-method, #key, #all-keys)
  => ()
  next-method();
  let packet-socket = socket($PF-PACKET, $SOCK-RAW, htons($ETH-P-ALL));
  interface.unix-file-descriptor := packet-socket;
  up(interface);
  if (packet-socket == -1)
    error("Error opening socket\n");
  else
    with-stack-structure (sockaddr :: <sockaddr-ll*>)
      sockaddr.sll-family   := $AF-PACKET;
      sockaddr.sll-protocol := htons($ETH-P-ALL);
      sockaddr.sll-ifindex  := name-to-index(packet-socket, interface.name);
      if (bind(packet-socket, sockaddr, size-of(<sockaddr-ll>)) == -1)
        format-out("Couldn't bind\n");
      end if;
    end;
   end if;
end method initialize;

define method int-close (int :: <interface>)
  close(int.unix-file-descriptor);
end;

define method up (interface :: <interface>)
 => ()
  with-stack-structure (ifreq :: <ifreq*>)
    ifreq.ifr-name := interface.name;
    //format-out("UP: %= %=\n", interface.name, interface.unix-file-descriptor);
    let res = ioctl(interface.unix-file-descriptor, $SIOCGIFFLAGS, ifreq);
    if (res == -1)
      error("Couldn't get IFFLAGS\n");
    else
      ifreq.ifr-flags := logior(ifreq.ifr-flags,
                                logior($IFF-UP, $IFF-PROMISC));
      let result = ioctl(interface.unix-file-descriptor, $SIOCSIFFLAGS, ifreq);
      if (result == -1)
        error("Error setting interface %s up\n", interface.name);
      end if;
    end if;
  end with-stack-structure;
end method;

define method find-all-devices () => (res :: <collection>)
  let packet-socket = socket($PF-PACKET, $SOCK-RAW, htons($ETH-P-ALL));
  let res = make(<stretchy-vector>);
  with-stack-structure (ifreq :: <ifreq*>)
    for (i from 0 below 256)
      ifreq.ifr-ifindex := i;
      if (ioctl(packet-socket, $SIOCGIFNAME, ifreq) >= 0)
        add!(res, ifreq.ifr-name);
      end;
    end;
  end;
  close(packet-socket);
  res;
end;

define method device-name (a :: <string>) => (res :: <string>)
  a;
end;

define method receive (interface :: <interface>)
  => (buffer)
  let buffer = make(<buffer>, size: $ethernet-buffer-size);
  local method unix-receive ()
          let fd = interface.unix-file-descriptor;
          let read-bytes =
            interruptible-system-call(unix-recv-buffer(fd,
                                                       buffer-offset(buffer, 0),
                                                       $ethernet-buffer-size,
                                                       0));
            if (read-bytes == -1)
              //Only want to catch $EINTR, but getting mps assertion failures
              //this is now done via interruptible-system-call macro
              #f;
            else
              subsequence(buffer, end: read-bytes);
            end if;
        end method;
  unix-receive();
end method receive;

define method send (interface :: <interface>, buffer :: <buffer>)
  unix-send-buffer(interface.unix-file-descriptor,
                   buffer-offset(buffer, 0),
                   buffer.size,
                   0);
end method send;

define function buffer-offset
    (the-buffer :: <buffer>, data-offset :: <integer>)
 => (result-offset :: <machine-word>)
  u%+(data-offset,
      primitive-wrap-machine-word
        (primitive-repeated-slot-as-raw
           (the-buffer, primitive-repeated-slot-offset(the-buffer))))
end function;


define class <ethernet-interface> (<filter>)
  slot unix-interface :: <interface>;
  slot interface-name :: <string>, required-init-keyword: name:;
  slot running? :: <boolean> = #t;
end;

define method initialize (node :: <ethernet-interface>,
                          #rest rest, #key, #all-keys)
  next-method();
  node.unix-interface := make(<interface>, name: node.interface-name);
end;

define method push-data-aux (input :: <push-input>,
                             node :: <ethernet-interface>,
                             frame :: <ethernet-frame>)
  send(node.unix-interface, as(<byte-vector>, assemble-frame(frame).packet));
end;

define method toplevel (node :: <ethernet-interface>)
  while(node.running?)
    let packet = receive(node.unix-interface);
    let frame = parse-frame(<ethernet-frame>, packet);
    push-data(node.the-output, frame);
  end while;
  int-close(node.unix-interface);
end;
