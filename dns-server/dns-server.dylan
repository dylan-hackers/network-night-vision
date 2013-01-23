module: dns-server
synopsis: 
author: 
copyright: 

define class <dns-server> (<filter>)
end;

define method push-data-aux
    (input :: <push-input>, node :: <dns-server>, data :: <dns-frame>) => ()
  format-out("BALH\n");
  format-out("received %=\n", data);
  if (data.query-or-response == #"query" &
        data.question-count == 1)
    format-out("FIRST CHECK\n");
    let question = data.questions.first;
    format-out("question is %s\n", as(<string>, question.domainname));
    if ( //as(<string>, question.domainname) = "foo.de." &
          question.question-type == #"A")
      format-out("BUILDING ANSWER\n");
      force-output(*standard-output*);
      let na = as(<string>, question.domainname);
      let nam = copy-sequence(na, end: na.size - 1);
      let d1 = as(<domain-name>, nam);
      let quest = dns-question(domainname: d1,
                               question-type: question.question-type,
                               question-class: question.question-class);
      d1.parent := quest;
      let d2 = as(<domain-name>, nam);
      let answer = a-host-address(domainname: d2,
                                  ttl: big-endian-unsigned-integer-4byte(#(#x0, #x0, #x0, #x1)),
                                  ipv4-address: ipv4-address("127.0.0.1"));
      d2.parent := answer;
      format-out("answer is %=\n", answer);
      force-output(*standard-output*);
      let d3 = as(<domain-name>, nam);
      let d4 = as(<domain-name>, concatenate("ns.", nam));
      let ns = name-server(domainname: d3,
                           ttl: big-endian-unsigned-integer-4byte(#(#x0, #x0, #x0, #x1)),
                           ns-name: d4);
      d3.parent := ns;
      d4.parent := ns;
      format-out("NS is %=\n", ns);
      force-output(*standard-output*);
      let res = dns-frame(identifier: data.identifier,
                          query-or-response: #"response",
                          authoritative-answer: #t,
                          recursion-available: #t,
                          questions: list(quest),
                          answers: list(answer),
                          name-servers: list(ns));
      quest.parent := res;
      answer.parent := res;
      ns.parent := res;
      format-out("sending %=\n", res);
      force-output(*standard-output*);
      push-data(node.the-output, res);
    else
      format-out("not asked for foo.de a\n");
    end;
  else
    format-out("not a question or multiple.\n")
  end;
end;

define function main()
  let s = make(<flow-socket>, port: 53, frame-type: <dns-frame>);
  let dns = make(<dns-server>);
  connect(s, dns);
  connect(dns, s);
  toplevel(s);
end function main;

main();
