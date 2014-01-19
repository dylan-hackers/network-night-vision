module: sniffer
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define command-line <sniffer-argument-parser> ()
  synopsis "sniffer [options]",
    description: "Capture and display packets from a network interface.";
  option verbose?,
    help: "Verbose output, print whole packet",
    names: #("verbose", "v");
  option interface = "eth0",
    help: "Interface to listen on (defaults to eth0)",
    kind: <parameter-option>,
    names: #("interface", "i");
  option read-pcap,
    help: "Dump packets from given pcap file",
    kind: <parameter-option>,
    names: #("read-pcap", "r");
  option show-ethernet,
    help: "Show Ethernet header information",
    names: #("show-ethernet", "e");
  option write-pcap,
    help: "Also write packets to given pcap file",
    kind: <parameter-option>,
    names: #("write-pcap", "w");
  option filter,
    help: "Filter, ~, |, &, and bracketed filters",
    kind: <parameter-option>,
    names: #("filter", "f");
end;

define function main()
  let parser = make(<sniffer-argument-parser>);
  block ()
    parse-command-line(parser, application-arguments());
  exception (ex :: <help-requested>)
    exit-application(0);
  exception (ex :: <usage-error>)
    exit-application(2);
  end;

  let input-stream = if (parser.read-pcap)
                       make(<file-stream>,
                            locator: parser.read-pcap,
                            direction: #"input")
                     end;

  let source = if (input-stream)
                 make(<pcap-file-reader>,
                      stream: input-stream);
               else
                 make(<ethernet-interface>,
                      name: parser.interface);
               end if;

  let output-stream = if (parser.write-pcap)
                        make(<file-stream>,
                             locator: parser.write-pcap,
                             direction: #"output",
                             if-exists: #"replace")
                      end;
  let fan-out = make(<fan-out>);

  if (parser.filter)
    let frame-filter = make(<frame-filter>, frame-filter: parser.filter);
    connect(source, frame-filter);
    connect(frame-filter, fan-out);
  else
    connect(source, fan-out);
  end;

  if (output-stream)
    connect(fan-out, make(<pcap-file-writer>,
                          stream: output-stream));
  end;

  let output = make(if (parser.verbose?)
                      <verbose-printer>
                    else
                      <summary-printer>
                    end,
                    stream: *standard-output*);

  if (parser.show-ethernet)
    connect(fan-out, output)
  else
    let decapsulator = make(<decapsulator>);
    connect(fan-out, decapsulator);
    connect(decapsulator, output)
  end;

  toplevel(source);

  if (input-stream)
    close(input-stream);
  end;
  if (output-stream)
    close(output-stream);
  end;
end;

main();
