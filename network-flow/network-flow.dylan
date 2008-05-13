Module:    network-flow
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define class <undefined-field-error> (<error>)
end;

define class <summary-printer> (<single-push-input-node>)
  slot stream :: <stream>, required-init-keyword: stream:;
end;

define method recursive-summary (frame :: <header-frame>) => (res :: <string>)
  concatenate(summary(frame), "/", recursive-summary(frame.payload));
end;

define method recursive-summary (frame :: <frame>) => (res :: <string>)
  summary(frame);
end;
define method push-data-aux (input :: <push-input>,
                             node :: <summary-printer>,
                             frame :: <frame>)
  format(node.stream, "%s\n", recursive-summary(frame));
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


define class <encapsulator> (<filter>)
end;

define method push-data-aux (input :: <push-input>,
                             node :: <encapsulator>,
                             frame :: <frame>)
  if (frame.parent)
    push-data(node.the-output, frame.parent)
  else
    error("No parent found")
  end;
end;

define class <decapsulator> (<filter>)
end;

define method push-data-aux (input :: <push-input>,
                             node :: <decapsulator>,
                             frame :: <header-frame>)
  push-data(node.the-output, frame.payload)
end;

define open class <fan-in> (<single-push-output-node>)
  constant slot inputs :: <stretchy-vector> = make(<stretchy-vector>);
  constant slot %lock :: <lock> = make(<lock>);
end;

define method create-input
  (fan-in :: <fan-in>)
  let res = make(<push-input>, node: fan-in);
  with-lock(fan-in.%lock)
    add!(fan-in.inputs, res);
  end;
  res;
end;

define method connect (output :: <object>, fan-in :: <fan-in>)
  connect(output, create-input(fan-in));
end;

define method disconnect (output :: <object>, fan-in :: <fan-in>)
  let in = output.connected-input;
  disconnect(output, in);
  with-lock(fan-in.%lock)
    remove!(fan-in.inputs, in);
  end
end;

define method push-data-aux (input :: <push-input>,
                             node :: <fan-in>,
                             frame :: <frame>)
  push-data(node.the-output, frame);
end;
define class <fan-out> (<single-push-input-node>)
  constant slot outputs :: <stretchy-vector> = make(<stretchy-vector>);
  constant slot %lock :: <lock> = make(<lock>);
end;

define method get-outputs (fan-out :: <fan-out>) => (outputs)
  fan-out.outputs;
end;

define method create-output
 (fan-out :: <fan-out>)
  let res = make(<push-output>, node: fan-out);
  with-lock(fan-out.%lock)
    add!(fan-out.outputs, res);
  end;
  res;
end;

define method connect (fan-out :: <fan-out>, input :: <object>)
  connect(create-output(fan-out), input);
end;

define method disconnect (fan-out :: <fan-out>, input :: <object>)
  let out = input.connected-output;
  disconnect(out, input);
  with-lock(fan-out.%lock)
    remove!(fan-out.outputs, out);
  end;
end;
define method push-data-aux (input :: <push-input>,
                             node :: <fan-out>,
                             frame :: <frame>)
  let the-outputs =
    with-lock(node.%lock)
      copy-sequence(node.outputs)
    end;
  for (output in the-outputs)
    push-data(output, frame)
  end;
end;

define class <filtered-push-output> (<push-output>)
  slot frame-filter :: <filter-expression>,
    required-init-keyword: frame-filter:;
end;

define method output-label (output :: <filtered-push-output>) => (res)
  format-to-string("%=", output.frame-filter);
end;

define class <demultiplexer> (<single-push-input-node>)
  slot outputs :: <stretchy-vector> = make(<stretchy-vector>);
  constant slot %lock :: <lock> = make(<lock>);
end;

define method create-output-for-filter
  (demux :: <demultiplexer>, filter-string :: <string>)
 => (output :: <filtered-push-output>)
  create-output-for-filter(demux, parse-filter(filter-string))
end;

define method create-output-for-filter
  (demux :: <demultiplexer>, filter :: <filter-expression>)
 => (output :: <filtered-push-output>)
  make(<filtered-push-output>,
       frame-filter: filter,
       node: demux);
end;

define method connect (output :: <filtered-push-output>, input :: <push-input>)
  next-method();
  let demux = output.node;
  with-lock(demux.%lock)
    add!(demux.outputs, output);
  end;
end;

define method disconnect
  (output :: <filtered-push-output>, input :: <push-input>)
 => ();
  let demux = output.node;
  with-lock(demux.%lock)
    remove!(demux.outputs, output);
  end;
  next-method();
end;

define method push-data-aux (input :: <push-input>,
                             node :: <demultiplexer>,
                             frame :: <frame>)
  let the-outputs =
    with-lock(node.%lock)
      copy-sequence(node.outputs)
    end;
  for (output in the-outputs)
    if(matches?(frame, output.frame-filter))
      push-data(output, frame)
    end
  end
end;

define method get-outputs (node :: <demultiplexer>) => (outputs)
  node.outputs;
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
  let pcap-file = parse-frame(<pcap-file>, stream-contents(reader.file-stream));
  for(frame in pcap-file.packets)
    push-data(reader.the-output, payload(frame));
  end;
end;

define class <pcap-file-writer> (<single-push-input-node>)
  slot file-stream :: <stream>, required-init-keyword: stream:;
end;

define method initialize (writer :: <pcap-file-writer>,
                          #rest rest, #key, #all-keys)
  next-method();
  write(writer.file-stream, packet(assemble-frame(make(<pcap-file-header>))));
  force-output(writer.file-stream);
end;

define method push-data-aux (input :: <push-input>,
                             node :: <pcap-file-writer>,
                             frame :: <frame>)
  write(node.file-stream,
        packet(assemble-frame(make(<pcap-packet>,
                                   payload: frame))));
  force-output(node.file-stream);
end;

define method push-data-aux (input :: <push-input>,
                             node :: <pcap-file-writer>,
                             frame :: <pcap-packet>)
  write(node.file-stream,
        packet(assemble-frame(frame)));
  force-output(node.file-stream);
end;

define class <malformed-packet-writer> (<filter>)
  slot file-stream, required-init-keyword: file:;
  slot pcap-writer :: false-or(<pcap-file-writer>) = #f;
end;

define method make (class == <malformed-packet-writer>,
                    #rest rest, #key file, #all-keys) => (res :: <malformed-packet-writer>)
  if (instance?(file, <string>))
    let fs = make(<file-stream>, locator: file, direction: #"output", if-exists: #"replace");
    make(class, file: fs);
  else
    next-method();
  end;
end;

define method push-data-aux (input :: <push-input>,
                             node :: <malformed-packet-writer>,
                             frame :: <frame>)
  block()
    push-data(node.the-output, frame);
  exception (e :: <malformed-packet-error>)
    unless (node.pcap-writer)
      node.pcap-writer := make(<pcap-file-writer>, stream: node.file-stream);
    end;
    //uh, we should somehow be connected to the pcap-writer
    push-data-aux(node.pcap-writer.the-input, frame)
  end;
end;

define class <completer> (<filter>)
  constant slot template-frame :: <frame>, required-init-keyword: template-frame:;
end;

define method push-data-aux (input :: <push-input>,
                             node :: <completer>,
                             frame :: <container-frame>);
  for (field in node.template-frame.fields)
    if (field.getter(frame) == $unsupplied)
      let default-field-value = field.getter(node.template-frame);
      if (default-field-value ~== $unsupplied)
        field.setter(default-field-value, frame);
      elseif (~ field.fixup-function)
        signal(make(<undefined-field-error>));
      end;
    end;
  end;
  push-data(node.the-output, frame);
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
