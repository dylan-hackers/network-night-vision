module: dns-server

define class <dns-server> (<filter>)
  constant slot zone :: <zone>, required-init-keyword: zone:;
end;

define method push-data-aux
    (input :: <push-input>, dns :: <dns-server>, data :: <dns-frame>) => ()
  //dbg("received %=\n", data);
  let remote-ip-c = dns.the-output.connected-input.node.reply-addr;
  let remote-ip = make(<ipv4-network-order-address>,
                       address: remote-ip-c);
  if (data.query-or-response == #"query" &
        data.question-count == 1)
    let question = data.questions.first;
    let q = as(<string>, question.domainname);
    let que =
      if (q.size > 0)
        copy-sequence(q, end: q.size - 1); //cut off last '.'
      else
        q
      end;
    let type = question.question-type;

    //TODO: check authority!

    let answers = choose(rcurry(entry-matches?, type, que), dns.zone.entries);

    dbg("%s ?%s%s [%d answers]\n", as(<string>, remote-ip), type.dns-query-entry, que, answers.size);
    //dbg("answers: %d\n", answers.size);
    //for (x in answers, i from 0)
    //  dbg("answer %d: %=\n", i, x);
    //end;

    let d1 = as(<domain-name>, que);
    let quest = dns-question(domainname: d1,
                             question-type: question.question-type,
                             question-class: question.question-class);
    d1.parent := quest;

    let frs = map(rcurry(produce-frame, que), answers);

    let res = dns-frame(identifier: data.identifier,
                        query-or-response: #"response",
                        authoritative-answer: #t,
                        recursion-available: #t,
                        questions: list(quest),
                        answers: frs);
    quest.parent := res;
    do(method(x) x.parent := res end, frs);
    push-data(dns.the-output, res);
  else
    format-out("not a question or multiple.\n")
  end;
end;

define function dbg (#rest args)
  apply(format-out, args);
  force-out();
end;

