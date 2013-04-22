module: dns-server

define class <dns-server> (<filter>)
  constant slot zone :: <zone>, required-init-keyword: zone:;
end;

define method push-data-aux
    (input :: <push-input>, node :: <dns-server>, data :: <dns-frame>) => ()
  //dbg("received %=\n", data);
  if (data.query-or-response == #"query" &
        data.question-count == 1)
    let question = data.questions.first;
    let q = as(<string>, question.domainname);
    let que = copy-sequence(q, end: q.size - 1); //cut off '.'
    let type = question.question-type;

    //TODO: check authority!

    dbg("question: ?%s%s\n", dns-query-entry(question.question-type), que);
    let poss-entries = choose(method (x)
                                x.fully-qualified-domain-name = que
                              end, node.zone.entries);
    let real-entries =
      if (type == #"ANY")
        poss-entries;
      else
        choose(method (x)
                 x.entry-type == type
               end, poss-entries);
      end;

    let cnames =
      if ((type == #"CNAME") | (type == #"ANY"))
        #(); //don't answer several times!
      else
        choose(method (x)
                 x.entry-type == #"CNAME"
               end, poss-entries);
      end;
    //dbg("cname-entries %=\n", cnames);
    //dbg("real-entries %=\n", real-entries);
    let answers = concatenate(cnames, real-entries);

    for (x in answers, i from 0)
      dbg("answer %d: %=\n", i, x);
    end;

    if (answers.size > 0)
      let d1 = as(<domain-name>, que);
      let quest = dns-question(domainname: d1,
                               question-type: question.question-type,
                               question-class: question.question-class);
      d1.parent := quest;

      let frs = map(produce-frame, answers);

      let res = dns-frame(identifier: data.identifier,
                          query-or-response: #"response",
                          authoritative-answer: #t,
                          recursion-available: #t,
                          questions: list(quest),
                          answers: frs);
      quest.parent := res;
      do(method(x) x.parent := res end, frs);
      push-data(node.the-output, res);
    end;
  else
    format-out("not a question or multiple.\n")
  end;
end;

define function dbg (#rest args)
  apply(format-out, args);
  force-output(*standard-output*);
end;

define function main()
  let s = make(<flow-socket>, port: 53, frame-type: <dns-frame>);
  let data = read-zone("myzone.txt");
  for (x in data.entries, i from 0)
    dbg("entry[%d]: %=\n", i, x)
  end;
  let dns = make(<dns-server>, zone: data);
  connect(s, dns);
  connect(dns, s);
  toplevel(s);
end function main;

main();
