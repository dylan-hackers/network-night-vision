module: sniffer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define argument-parser <sniffer-argument-parser> ()
  synopsis print-synopsis,
    usage: "sniffer [options]",
    description: "Capture and display packets from a network interface.";
  option verbose?, "Verbose output, print whole packet",
    short: "v", long: "verbose";
  option interface = "eth0", "Interface to listen on (defaults to eth0)",
    kind: <parameter-option-parser>, long: "interface", short: "i";
  option read-pcap, "Dump packets from given pcap file",
    kind: <parameter-option-parser>, long: "read-pcap", short: "r";
  option write-pcap, "Also write packets to given pcap file",
    kind: <parameter-option-parser>, long: "write-pcap", short: "w";
  option filter, "Filter, ~, |, &, and bracketed filters",
    kind: <parameter-option-parser>, long: "filter", short: "f";
end;

define function main()
  let parser = make(<sniffer-argument-parser>);
  unless(parse-arguments(parser, application-arguments()))
    print-synopsis(parser, *standard-output*);
    exit-application(0);
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
    let frame-filter = make(<frame-filter>, filter-expression: parser.filter);
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

  connect(fan-out, output);
  
  toplevel(source);
  
  if (input-stream)
    close(input-stream);
  end;
  if (output-stream)
    close(output-stream);
  end;
end;

main();
