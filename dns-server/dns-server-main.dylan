module: dns-server


define method main ()
  //listen socket: default 53
  //config file, default: data
  let parser = make(<command-line-parser>);
  add-option(parser,
             make(<parameter-option>,
                  names: #("socket"),
                  help: "Listening socket"));
  block ()
    parse-command-line(parser, application-arguments(),
                       description: "The most excellent Frobber.");
  exception (ex :: <help-requested>)
    exit-application(0);
  exception (ex :: <usage-error>)
    exit-application(2);
  end;

  let socketopt :: false-or(<string>) = get-option-value(parser, "socket");
  let port = if (socketopt) string-to-integer(socketopt) else 53 end;

  let s =
    block ()
      make(<flow-socket>, port: port, frame-type: <dns-frame>);
    exception (e :: <condition>)
      exit-application(-1);
    end;

  let args :: <sequence> = positional-options(parser);
  let zonefile = if (args.size > 0) args[0] else "data" end;
  let data =
    block ()
      read-zone(zonefile);
    exception (e :: <condition>)
      exit-application(-1);
    end;

  //for (x in data.entries, i from 0)
  //  dbg("entry[%d]: %=\n", i, x)
  //end;
  dbg("read %d entries from %s, listening on port %d\n",
      data.entries.size, zonefile, port);
  let dns = make(<dns-server>, zone: data);
  connect(s, dns);
  connect(dns, s);
  toplevel(s);
end;


main();
