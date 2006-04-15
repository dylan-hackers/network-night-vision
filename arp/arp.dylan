Module:    arp
Synopsis:  arp layer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.


define sealed class <vector-table> (<table>)
end class;

define method table-protocol (table :: <vector-table>)
 => (test-function :: <function>, hash-function :: <function>)
  values(method (x :: <fixed-size-byte-vector-frame>, y :: <fixed-size-byte-vector-frame>)
           x = y end, vector-hash);
end method table-protocol; 

define method vector-hash (vector :: <fixed-size-byte-vector-frame>, state :: <hash-state>)
  => (id :: <integer>, state :: <hash-state>)
  let hash = 0;
  for (number in vector.data)
    hash := hash + number;
  end for;
  values(hash, state);
end method;

define class <arp-handler> (<filter>)
  constant slot arp-mac-address :: false-or(<mac-address>) = #f, init-keyword: mac-address:;
  constant slot arp-ipv4-address :: false-or(<ipv4-address>) = #f, init-keyword: ipv4-address:;
  constant slot arp-cache :: <vector-table> = make(<vector-table>);
end;

define method push-data-aux (input :: <push-input>,
                             node :: <arp-handler>,
                             frame :: <frame>)
  //expect to get an <arp-frame> here
  if (frame.operation = 1) //arp who-has
    let ip = frame.target-ip-address;
    if (ip = node.arp-ipv4-address)
      format-out("IP %s\n", as(<string>, ip));
      let response = make(<arp-frame>,
                          operation: 2,
                          source-mac-address: node.arp-mac-address,
                          source-ip-address: ip,
                          target-mac-address: frame.source-mac-address,
                          target-ip-address: frame.source-ip-address);
      send(response, frame.parent, node.the-output);
    end;
  elseif (frame.operation = 2) //ip is at
    if (frame.target-ip-address = node.arp-ipv4-address)
      unless (element(node.arp-cache, frame.source-ip-address, default: #f))
        node.arp-cache[frame.source-ip-address] := frame.source-mac-address
      end;
    end;
  end;
end;

define method dump-arp-table (arp-handler :: <arp-handler>)
  let cache = arp-handler.arp-cache;
  for (ip in key-sequence(cache))
    format-out("%s is at %s\n", as(<string>, ip), as(<string>, cache[ip]));
  end;
end;

define class <ethernet-layer> (<filter>)
  slot arp-table :: <vector-table>, required-init-keyword: arp-table:;
  slot ethernet-address :: <mac-address>, required-init-keyword: ethernet-address:;
end;

define method send (frame :: <arp-frame>,
                    parent :: false-or(<ethernet-frame>),
                    node :: <ethernet-layer>)
  push-data(node.the-output,
            make(<ethernet-frame>,
                 source-address: frame.source-mac-address, //XXX
                 destination-address: frame.target-mac-address, //XXX
                 type-code: #x806, //XXX
                 payload: frame));
end;

define function find-mac (ip :: <ipv4-address>, arp-handler)
  send(make(<arp-frame>,
            operation: 1,
            source-mac-address: ,
            source-ip-address: ,
            target-mac-address: mac-address("00:00:00:00:00:00"),
            target-ip-address: ip));
end;

define method send (frame :: <ipv4-frame>,
                    parent :: false-or(<ethernet-frame>),
                    node :: <ethernet-layer>)
  let target-ip = frame.destination-address;
  unless (ip-in-subnet?(target-ip, node.subnet-address))
    target-ip := node.router-address;
  end;
  let target-mac = element(node.arp-table, target-ip, default: #f);
  unless (target-mac)
    target-mac := find-mac(target-ip);
    node.arp-table[target-ip] := target-mac;
  end;
  push-data(node.the-output,
            make(<ethernet-frame>,
                 source-address: node.ethernet-address,
                 destination-address: target-mac,
                 type-code: #x800,
                 payload: frame));
end;

/*
define class <icmp-handler> (<filter>)
end;

define method push-data-aux (input :: <push-input>,
                             node :: <icmp-handler>,
                             frame :: <frame>)
  if (frame.type = 8 & frame.code = 0)
    push-data(node.the-output,
              make(<icmp-frame>,
                   type: 0,
                   code: 0,
                   payload: frame.payload));
  end;
end;

define class <ipv4-handler> (<filter>)
end;

define method push-data-aux (input :: <push-input>,
                             node :: <ipv4-handler>,
                             frame :: <frame>)
  push-data(node.the-output,
            make(<ipv4-frame>,
                 //initvals));
end;
*/
define function main()
  let arp-handler = make(<arp-handler>,
                         mac-address: mac-address("00:de:ad:be:ef:00"),
                         ipv4-address: ipv4-address("193.17.43.124"));
  let source = make(<ethernet-interface>, name: "eth0");
  let decap = make(<decapsulator>);
  let demux = make(<demultiplexer>);
  let arp-output = create-output-for-filter(demux, "arp");
  let printer = make(<verbose-printer>, stream: *standard-output*);
  let fan-out = make(<fan-out>);
  let ethernet = make(<ethernet-layer>,
                      arp-table: arp-handler.arp-cache,
                      ethernet-address: arp-handler.arp-mac-address);
  connect(source, decap);
  connect(decap, demux);
  connect(arp-output, arp-handler);
  connect(arp-handler, fan-out);
  connect(fan-out, printer);
  connect(fan-out, ethernet);
  connect(ethernet, source);
  let thr = make(<thread>,
                 function:
                   method()
                       sleep(3);
                       while(#t)
                         dump-arp-table(arp-handler);
                         format-out("\n\n");
                         sleep(10)
                       end;
                   end);
  toplevel(source);
end;

begin
  main();
end;