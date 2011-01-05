module: pcap-live-interface
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define class <packet-flow-node> (<filter>)
  slot unix-file-descriptor :: <integer>;
end class;

define constant $ethernet-buffer-size :: <integer> = 1548;
define constant <buffer> = <byte-vector>;

define layer phy (<physical-layer>)
  property promiscuous? :: <boolean> = #t;
  property device-name :: <string> = "";
  slot packet-flow-node :: <packet-flow-node> = make(<packet-flow-node>);
  slot demultiplexer :: <demultiplexer> = make(<demultiplexer>);
  slot fan-in :: <fan-in> = make(<fan-in>);
  slot fan-out :: <fan-out> = make(<fan-out>);
end;

define method initialize-layer (layer :: <phy-layer>,
                                #key, #all-keys)
 => ()
  connect(layer.packet-flow-node, layer.demultiplexer);
  connect(layer.fan-in, layer.fan-out);
  connect(layer.fan-out, layer.packet-flow-node);
  register-c-dylan-object(layer.packet-flow-node);
  register-property-changed-event(layer, #"administrative-state",
                                  toggle-administrative-state);
end;

define function toggle-administrative-state (event :: <property-changed-event>)
 => ();
  let property = event.property-changed-event-property;
  let layer = property.property-owner;
  if (property.property-value == #"up")
    make(<thread>, function: curry(run-interface, layer));
  else
    layer.@running-state := #"down";    
  end;
end;

define method check-upper-layer? (lower :: <phy-layer>, upper :: <layer>)
 => (allowed? :: <boolean>);
  #t
end;

define method check-socket-arguments? (lower :: <phy-layer>, #rest rest, #key type, #all-keys)
 => (valid-arguments? :: <boolean>)
  //XXX: if (valid-type?)
  type == <ethernet-frame>
end;


define method create-socket (lower :: <phy-layer>, #rest rest, #key type, filter-string, tap?, #all-keys)
 => (socket :: <socket>)
  let filter-string = filter-string | "ethernet";
  if (tap?)
    create-tapping-socket(lower, lower.fan-out, lower.demultiplexer, filter-string: filter-string);
  else
    let input = create-input(lower.fan-in);
    let output = create-output-for-filter(lower.demultiplexer, filter-string);
    make(<input-output-socket>, owner: lower, input: input, output: output);
  end;
end;


define method push-data-aux (input :: <push-input>,
                             node :: <packet-flow-node>,
                             frame :: <ethernet-frame>)
  let buffer = as(<byte-vector>, assemble-frame(frame).packet);
  unix-send-buffer(node.unix-file-descriptor,
                   buffer-offset(buffer, 0),
                   buffer.size,
                   0);
end;

define function run-interface (layer :: <phy-layer>)
  block(return)
    let node = layer.packet-flow-node;
    let handle = socket($PF-PACKET, $SOCK-RAW, htons($ETH-P-ALL));
    if (handle == -1)
      layer.@running-state := #"down";
      return();
    end;
    node.unix-file-descriptor := handle;

    with-stack-structure (ifreq :: <ifreq*>)
      ifreq.ifr-name := layer.@device-name;
      let res = ioctl(node.unix-file-descriptor, $SIOCGIFFLAGS, ifreq);
      if (res == -1)
        layer.@running-state := #"down";
        return();
      else
        ifreq.ifr-flags := logior(ifreq.ifr-flags,
                                  logior($IFF-UP, if (layer.@promiscuous?)
                                                    $IFF-PROMISC
                                                  else
                                                    0
                                                  end));
        let result = ioctl(node.unix-file-descriptor, $SIOCSIFFLAGS, ifreq);
        if (result == -1)
          layer.@running-state := #"down";
          return();
        end if;
      end if;
    end with-stack-structure;

    with-stack-structure (sockaddr :: <sockaddr-ll*>)
      sockaddr.sll-family   := $AF-PACKET;
      sockaddr.sll-protocol := htons($ETH-P-ALL);
      sockaddr.sll-ifindex  := name-to-index(node.unix-file-descriptor,
                                             layer.@device-name);
      if (bind(node.unix-file-descriptor, sockaddr, size-of(<sockaddr-ll>)) == -1)
        layer.@running-state := #"down";
        return();
      end if;
    end;
    layer.@running-state := #"up";

    while(layer.@running-state == #"up")
      let (packet, type-code) = receive(node);
      let type = select (type-code)
                   1   => <ethernet-frame>;
                   801 => <ieee80211-frame>;
                   802 => <prism2-frame>;
                   803 => <bsd-80211-radio-frame>;
                 end;
      block()
        let frame = parse-frame(type, packet);
        push-data(node.the-output, frame);
      exception (e :: <error>)
        //format-out("Incoming packet broken beyond repair\n");
      end
    end while;
    close(node.unix-file-descriptor);
  end;
end;

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

define function start-packet ()
  let packet-socket = socket($PF-PACKET, $SOCK-RAW, htons($ETH-P-ALL));
  with-stack-structure (ifreq :: <ifreq*>)
    for (i from 0 below 256)
      ifreq.ifr-ifindex := i;
      if (ioctl(packet-socket, $SIOCGIFNAME, ifreq) >= 0)
        make(<phy-layer>, device-name: as(<byte-string>, ifreq.ifr-name));
      end;
    end;
  end;
  close(packet-socket);
end;

define method receive (interface :: <packet-flow-node>)
  => (buffer, type)
  let buffer = make(<buffer>, size: $ethernet-buffer-size);
  local method unix-receive ()
          with-stack-structure (sockaddr :: <sockaddr-ll*>)
            with-stack-structure (sockaddr-size :: <socklen-t*>)
              pointer-value(sockaddr-size) := size-of(<sockaddr-ll>);
              let fd = interface.unix-file-descriptor;
              let read-bytes =
                interruptible-system-call(unix-recv-buffer-from(fd,
                                                                buffer-offset(buffer, 0),
                                                                $ethernet-buffer-size,
                                                                0,
                                                                sockaddr,
                                                                sockaddr-size));
                if (read-bytes == -1)
                  //Only want to catch $EINTR, but getting mps assertion failures
                  //this is now done via interruptible-system-call macro
                  #f;
                else
                  values(subsequence(buffer, end: read-bytes), sockaddr.sll-hatype);
                end if;
              end
            end
        end method;
  unix-receive();
end method receive;

define function buffer-offset
    (the-buffer :: <buffer>, data-offset :: <integer>)
 => (result-offset :: <machine-word>)
  u%+(data-offset,
      primitive-wrap-machine-word
        (primitive-repeated-slot-as-raw
           (the-buffer, primitive-repeated-slot-offset(the-buffer))))
end function;


begin
  register-startup-function(start-packet);
end;