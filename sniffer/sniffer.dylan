module: sniffer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define argument-parser <sniffer-argument-parser> ()
  synopsis print-synopsis,
    usage: "sniffer [options]",
    description: "Capture and display packets from a network interface.";
  option verbose?, short: "v", long: "verbose";
  option interface = "eth0",
    kind: <parameter-option-parser>, long: "interface", short: "i";
  option filter,
    kind: <parameter-option-parser>, long: "filter", short: "f";
end;

define function join(joiner :: <string>, strings :: <collection>)
  if(strings.size = 0)
    ""
  else
    reduce1(method (x, y) concatenate(x, joiner, y) end, strings);
  end;
end;

define function main()
  let parser = make(<sniffer-argument-parser>);
  unless(parse-arguments(parser, application-arguments()))
    print-synopsis(parser, *standard-output*);
    exit-application(0);
  end;

  let source = make(<ethernet-interface>, name: parser.interface);
  let printer = make(if (parser.verbose?)
                       <verbose-printer>
                     else
                       <summary-printer>
                     end);

  if (parser.filter)
    let frame-filter = make(<frame-filter>, filter-expression: parser.filter);
    connect(source, frame-filter);
    connect(frame-filter, printer);
  else
    connect(source, printer);
  end;

  toplevel(source);
end;

main();
