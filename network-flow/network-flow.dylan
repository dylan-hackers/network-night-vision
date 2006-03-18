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
  let output = make(<filtered-push-output>, frame-filter: filter);
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

define class <pcap-file-reader> (<single-push-output-node>)
  slot file-name :: <string>, required-init-keyword: name:;
end;

define method toplevel (reader :: <pcap-file-reader>)
  let file = as(<byte-vector>, with-open-file (stream = reader.file-name,
                                               direction: #"input")
                                 stream-contents(stream);
                               end);
  let pcap-file = parse-frame(<pcap-file>, file);
  for(frame in pcap-file.packets)
    push-data(reader.the-output, frame)
  end
end;                    

begin
  let reader = make(<pcap-file-reader>, name: "c:\\dylan\\capture.pcap");
  let printer = make(<summary-printer>, stream: *standard-output*);
  let decapsulator = make(<decapsulator>);
  connect(reader, decapsulator);
  connect(decapsulator, printer);
  toplevel(reader);
end;
      
