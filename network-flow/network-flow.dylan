Module:    network-flow
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define class <summary-printer> (<single-push-input-node>)
  slot stream :: <stream>, required-init-keyword: stream:;
end;

define method push-data-aux (input :: <push-input>,
                             node :: <summary-printer>,
                             frame :: <frame>)
  format(node.stream, "%s\n", summary(frame));
  force-output(node.stream);
end;

define class <verbose-printer> (<single-push-input-node>)
  slot stream :: <stream>, required-init-keyword: stream:;
end;

define method push-data-aux (input :: <push-input>,
                             node :: <verbose-printer>,
                             frame :: <frame>)
  format(node.stream, "%s\n", as(<string>, frame));
  force-output(node.stream);
end;


define class <decapsulator> (<filter>)
end;

define method push-data-aux (input :: <push-input>,
                             node :: <decapsulator>,
                             frame :: <header-frame>)
  push-data(node.the-output, frame.payload)
end;

define class <demultiplexer> (<single-push-input-node>)
  slot outputs :: <stretchy-vector> = make(<stretchy-vector>);
end;

define class <fan-in> (<single-push-output-node>)
  slot inputs :: <stretchy-vector> = make(<stretchy-vector>);
end;

define method create-input
  (fan-in :: <fan-in>)
  let res = make(<push-input>, node: fan-in);
  add!(fan-in.inputs, res);
  res;
end;

define method connect (output :: <object>, fan-in :: <fan-in>)
  connect(output, create-input(fan-in));
end;

define method push-data-aux (input :: <push-input>,
                             node :: <fan-in>,
                             frame :: <frame>)
  push-data(node.the-output, frame);
end;
define class <fan-out> (<single-push-input-node>)
  slot outputs :: <stretchy-vector> = make(<stretchy-vector>);
end;

define method create-output
 (fan-out :: <fan-out>)
  let res = make(<push-output>, node: fan-out);
  add!(fan-out.outputs, res);
  res;
end;

define method connect (fan-out :: <fan-out>, input :: <object>)
  connect(create-output(fan-out), input);
end;

define method push-data-aux (input :: <push-input>,
                             node :: <fan-out>,
                             frame :: <frame>)
  for (output in node.outputs)
    push-data(output, frame)
  end;
end;

define class <filtered-push-output> (<push-output>)
  slot frame-filter :: <filter-expression>,
    required-init-keyword: frame-filter:;
end;

define method create-output-for-filter
  (demux :: <demultiplexer>, filter-string :: <string>)
 => (output :: <filtered-push-output>)
  create-output-for-filter(demux, parse-filter(filter-string))
end;

define method create-output-for-filter
  (demux :: <demultiplexer>, filter :: <filter-expression>)
 => (output :: <filtered-push-output>)
  let output = make(<filtered-push-output>,
                    frame-filter: filter,
                    node: demux);
  add!(demux.outputs, output);
  output
end;

define method push-data-aux (input :: <push-input>,
                             node :: <demultiplexer>,
                             frame :: <frame>)
  for (output in node.outputs)
    if(matches?(frame, output.frame-filter))
      push-data(output, frame)
    end
  end
end;

define class <frame-filter> (<filter>)
  slot frame-filter :: <filter-expression>,
    required-init-keyword: frame-filter:;
end;

define method make (class == <frame-filter>,
                    #rest rest,
                    #key frame-filter,
                    #all-keys) => (res :: <frame-filter>)
  if (instance?(frame-filter, <string>))
    apply(next-method, class, frame-filter: parse-filter(frame-filter), rest);
  else
    apply(next-method, class, rest);
  end if;
end;

define method push-data-aux (input :: <push-input>,
                             node :: <frame-filter>,
                             frame :: <frame>)
  if (matches?(frame, node.frame-filter))
    push-data(node.the-output, frame)
  end;
end;

define class <pcap-file-reader> (<single-push-output-node>)
  slot file-stream :: <stream>, required-init-keyword: stream:;
end;

define method toplevel (reader :: <pcap-file-reader>)
  let file = as(<byte-vector>, stream-contents(reader.file-stream));
  let pcap-file = make(unparsed-class(<pcap-file>), packet: file);
  //  push-data(reader.the-output, pcap-file.header);
  let push-out = select (get-frame-field(#"linktype", pcap-file.header).value)
                   $DLT-EN10MB =>
                     method (r, f)
                       push-data(r.the-output,
                                 make(unparsed-class(<ethernet-frame>),
                                      packet: assemble-frame(f.payload)));
                     end method;
                   $DLT-PRISM-HEADER =>
                     method (r, f)
                       push-data(r.the-output,
                                 make(unparsed-class(<prism2-frame>),
                                      packet: assemble-frame(f.payload)));
                     end method;
                 end select;
  for(frame in pcap-file.packets)
    push-out(reader, frame);
  end;
end;

define class <pcap-file-writer> (<single-push-input-node>)
  slot file-stream :: <stream>, required-init-keyword: stream:;
end;

define method initialize (writer :: <pcap-file-writer>,
                          #rest rest, #key, #all-keys)
  next-method();
  write(writer.file-stream, assemble-frame(make(<pcap-file-header>)));
  force-output(writer.file-stream);
end;

define method push-data-aux (input :: <push-input>,
                             node :: <pcap-file-writer>,
                             frame :: <frame>)
  write(node.file-stream,
        assemble-frame(make(<pcap-packet>,
                            payload: frame)));
  force-output(node.file-stream);
end;


/*
begin
  let interface = make(<ethernet-interface>, name: "eth0");
  //let reader = make(<pcap-file-reader>, name: "club.pcap");
  let printer = make(<summary-printer>, stream: *standard-output*);
  let decapsulator = make(<decapsulator>);
  let ip-decap = make(<decapsulator>);
  //let filter = make(<frame-filter>, filter-expression: "ip.source-address = 23.23.23.221");
  connect(interface, decapsulator);
  //connect(decapsulator, ip-decap);
  //connect(ip-decap, filter);
  connect(decapsulator, printer);
  toplevel(interface);
end;
*/    
