module: sniffer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define class <source> (<object>)
  slot listeners = make(<stretchy-vector>);
end;

define class <sink> (<object>)
  slot filter :: <function> = always(#t), init-keyword: filter:;
end;

define generic push-frame (sink :: <sink>, frame :: <frame>);

define class <callback-sink> (<sink>)
  slot callback :: <function>, required-init-keyword: callback:;
end class <callback-sink>;

define method push-frame (sink :: <callback-sink>, frame :: <frame>)
  sink.callback(frame);
end method push-frame;

define class <summary-printer> (<sink>)
  slot stream :: <stream>, required-init-keyword: stream:;
end class <summary-printer>;

define method push-frame (sink :: <summary-printer>, frame :: <frame>)
  format(sink.stream, "%s\n", summary(frame));
  force-output(sink.stream);
end method push-frame;

define class <verbose-printer> (<sink>)
  slot stream :: <stream>, required-init-keyword: stream:;
end class <verbose-printer>;

define method push-frame (sink :: <verbose-printer>, frame :: <frame>)
  format(sink.stream, "%s\n", as(<string>, frame));
  force-output(sink.stream);
end method push-frame;

define class <ip-accounting> (<sink>)
  slot traffic-table = make(<vector-table>);
  slot lock = make(<lock>);
end;

define method push-frame (sink :: <ip-accounting>, frame :: <frame>)
  if (instance?(frame.payload, <ipv4-frame>))
    let ip-frame = frame.payload;
    local method account-for (ipv4 :: <ipv4-address>)
            if (ipv4.data[0] = 193 & ipv4.data[1] = 17)
              let old-value =  element(sink.traffic-table, ipv4, default: 0.0d0);
              sink.traffic-table[ipv4] := old-value + ip-frame.total-length;
            end;
          end;
    with-lock(sink.lock)
      account-for(ip-frame.source-address);
      account-for(ip-frame.destination-address);
    end;
  end;
end;

define class <arp-responder> (<sink>)
  constant slot mac-address, // :: <mac-address>,
    required-init-keyword: mac-address:;
  constant slot ip-address, // :: <ipv4-address>,
    required-init-keyword: ip-address:;
  constant slot output-sink, // :: <ethernet-interface>,
    required-init-keyword: output-sink:;
end class <arp-responder>;

define method initialize(sink :: <arp-responder>,
                         #rest args, #key, #all-keys)
  next-method();
  let response = make(<arp-frame>,
                      operation: 1,
                      source-mac-address: sink.mac-address,
                      source-ip-address: sink.ip-address,
                      target-mac-address: sink.mac-address,
                      target-ip-address: sink.ip-address);
    let response* = make(<decoded-ethernet-frame>,
                         destination-address: 
                           parse-frame(<mac-address>, 
                                       as(<byte-vector>,
                                          #(#xff, #xff, #xff, #xff, #xff, #xff))),
                         source-address: sink.mac-address,
                         type-code: #x806,
                         payload: response);
    format(*standard-output*, "%=\n", summary(response*));
    force-output(*standard-output*);
    push-frame(sink.output-sink, response*);
end method initialize;

define method push-frame (sink :: <arp-responder>,
                          frame :: <frame>)
  let arp-request = frame.payload;
  if(instance?(arp-request, <arp-frame>)
    & arp-request.operation = 1
    & arp-request.target-ip-address = sink.ip-address)
    let response = make(<arp-frame>,
                        operation: 2,
                        source-mac-address: sink.mac-address,
                        source-ip-address: sink.ip-address,
                        target-mac-address: arp-request.source-mac-address,
                        target-ip-address: arp-request.source-ip-address);
    let response* = make(<decoded-ethernet-frame>,
                         destination-address: frame.source-address,
                         source-address: sink.mac-address,
                         type-code: #x806,
                         payload: response);
    format(*standard-output*, "%=\n", summary(response*));
    force-output(*standard-output*);
    push-frame(sink.output-sink, response*);
  end if;
end method push-frame;

  

define method add-listener (source :: <source>,
                            listener :: <sink>);
  add!(source.listeners, listener)
end method add-listener;

define method remove-listener (source :: <source>,
                               listener :: <sink>);
  remove!(source.listeners, listener)
end method remove-listener;

define class <pcap-file-source> (<source>)
  slot file-name, required-init-keyword: name:;
end;

define method toplevel (source :: <pcap-file-source>) => ();
  let file = as(<byte-vector>, with-open-file (stream = source.file-name,
                                               direction: #"input")
                                 stream-contents(stream);
                               end);
  //format(*standard-output*, "file %=\n", file);
  let frame = parse-frame(<pcap-file>, file);
  let mybytes = map(method(x) assemble-frame(x.payload) end, frame.packets);
  //format(*standard-output*, "BYTES %d %=\n", mybytes.size, mybytes);
  for (i from 0 below 10000)
    let test-frames = map(method(x)
                            make(unparsed-class(<ethernet-frame>),
                                 packet: x)
                          end, mybytes);
    for (test-frame in test-frames)
      for(listener in source.listeners)
        push-frame(listener, test-frame);
      end for;
    end for;
  end for;
end;

define class <ethernet-interface> (<source>, <sink>)
  slot interface :: <interface>;
  slot name, required-init-keyword: name:;
end class <ethernet-interface>;

define method initialize (source :: <ethernet-interface>,
                         #rest keywords, #key, #all-keys)
  next-method();
  source.interface := make(<interface>, name: source.name);
end method initialize;

define method toplevel (source :: <ethernet-interface>) => ();
  while(#t)
    let packet = receive(source.interface);

    block ()
      let frame = make(unparsed-class(<ethernet-frame>), packet: packet);
      for(listener in source.listeners)
        push-frame(listener, frame);
      end for;
    exception (error :: <condition>)
      let frame = parse-frame(<ethernet-frame>, packet);
      format(*standard-output*,
             "%= handling packet\n%s\n",
             error,
             as(<string>, frame));
      hexdump(*standard-output*, packet);
      force-output(*standard-output*);
    end block;
  end while;
end method toplevel;

define method push-frame (sink :: <ethernet-interface>,
                          frame :: <frame>) => ();
  let packet = assemble-frame(frame);
  send(sink.interface, packet);
end method push-frame;

define method print-accounting-table-loop (accounting :: <ip-accounting>)
  let last-total = 0;
  let last-timestamp = current-timestamp();
  sleep(10);
  while(#t)
    let total = 0;
    let traffic-table = accounting.traffic-table;
    for (ip-address in 
           sort(key-sequence(traffic-table),
                test: method(x, y)
                          traffic-table[x] > traffic-table[y]
                      end),
         i from 0)
      total := total + traffic-table[ip-address];
      if (i < 20)
        format(*standard-output*,
               "%=\t%=\n",
               ip-address,
               traffic-table[ip-address]);
      end
    end;
    format(*standard-output*,
           "%= MB/sec, %= MB total\n\n",
           as(<single-float>, total - last-total) 
             /  (1024.0 * 1024.0 * 
                   (current-timestamp() - last-timestamp) / 1000.0),
           as(<single-float>, total) / 1024.0 / 1024.0);
    last-total := total;
    last-timestamp := current-timestamp();
    sleep(10);
  end;
end;

define function main(interface-name :: <string>,
                     #key verbose?)
  //let pcap-file = make(<pcap-file-source>, name: interface-name);

  let interface = make(<ethernet-interface>, name: interface-name);
  let printer = make(if (verbose?) 
                       <verbose-printer>
                     else
                       <summary-printer>
                     end,
                     stream: *standard-output*);
  /* let arp-responder 
    = make(<arp-responder>,
           mac-address: parse-frame(<mac-address>, 
                                    as(<byte-vector>,
                                       #(#xde, #xad, 0, 0, #xbe, #xee))),
           ip-address: parse-frame(<ipv4-address>, 
                                   as(<byte-vector>, #(193, 17, 43, 122))),
           output-sink: interface);
*/
  let accounting = make(<ip-accounting>);

//  add-listener(interface, printer);
//  add-listener(interface, arp-responder);
  add-listener(interface, accounting);

  let thr1 = make(<thread>, 
                  function: curry(print-accounting-table-loop, accounting));

  toplevel(interface);
end;

begin
  if(application-arguments().size > 1)
    main(application-arguments()[1], verbose?: #t)
  else
    main(application-arguments()[0])
  end;
end;
/*
begin
  let frame = parse-frame(<ipv4-frame>, $ipv4);
  format(*standard-output*, "%s\n", as(<string>, frame));
end;
  */
