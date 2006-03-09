module: packet-filter

define function extract-action
    (token-string :: <byte-string>,
     token-start :: <integer>, 	 
     token-end :: <integer>) 	 
 => (result :: <byte-string>); 	 
  copy-sequence(token-string, start: token-start, end: token-end);
end;


define constant $filter-tokens
  = simple-lexical-definition
      token AMP = "&";
      token PIPE = "\\|";
      token TILDE = "~";
      token EQUALS = "=";
      token DOT = "\\.";

      inert "([ \t]+)";
      token Name = "[a-zA-Z_0-9]",
         semantic-value-function: extract-action,
         priority: -1;
      token value = "[a-zA-Z_0-9:.]",
         semantic-value-function: extract-action,
         priority: -2;
end;

define constant $filter-productions
 = simple-grammar-productions
  production filter => [filter AMP filter], action:
    method(p :: <simple-parser>, data, s, e)
        make(<and-expression>, left: p[0], right: p[2]);
    end;

  production filter => [filter PIPE filter], action:
    method(p :: <simple-parser>, data, s, e)
        make(<or-expression>, left: p[0], right: p[2]);
    end;

  production filter => [TILDE filter], action:
    method(p :: <simple-parser>, data, s, e)
        make(<not-expression>, left: p[0]);
    end;

  production filter => [Name], action:
    method(p :: <simple-parser>, data, s, e)
        make(<frame-present>, frame: p[0]);
    end;

  production filter => [Name DOT Name EQUALS value], action:
    method(p :: <simple-parser>, data, s, e)
        make(<field-equals>, frame: p[0], name: p[2], value: p[4]);
    end;

  production compound-filter => [filter], action:
    method(p :: <simple-parser>, data, s, e)
        data := p[0];
    end;
end;

define constant $filter-automaton
  = simple-parser-automaton($filter-tokens, $filter-productions,
                            #[#"compound-filter"]);

define function main (name, arguments)
  let handler (<parser-automaton-shift/reduce-error>) =
    method (condition :: <parser-automaton-shift/reduce-error>,
            next-handler)
      format-out("shift/reduce error on token %s (choosing shift), productions: %=\n",
                 condition.parser-automaton-error-inputs.first);
      for (production in condition.parser-automaton-error-productions)
        format-out("  %s\n", production);
      end;
      signal(make(<parser-automaton-shift/reduce-restart>,
                  action: #"shift"));
    end method;


  let rangemap = make(<source-location-rangemap>);
  let scanner = make(<simple-lexical-scanner>,
                     definition: $filter-tokens,
                     rangemap: rangemap);
  let input = "ip.source-address = 23.23.23.23"; // & tcp.source-port = 23";
  let data = #();
  let parser = make(<simple-parser>,
                    automaton: $filter-automaton,
                    start-symbol: #"compound-filter",
                    rangemap: rangemap,
                    consumer-data: data);
  scan-tokens(scanner,
              simple-parser-consume-token,
              parser,
              input,
              end: input.size,
              partial?: #f);
  print-filter(data);
end;

define method print-filter (filter :: <frame-present>)
  format-out("frame present filter %=\n", filter.frame-name);
end;

define method print-filter (filter :: <field-equals>)
  format-out("field equals filter %= %= %=\n",
             filter.frame-name,
             filter.field-name,
             filter.field-value);
end;

define method print-filter (filter :: <and-expression>)
  format-out("and filter:");
  print-filter(filter.left-expression);
  print-filter(filter.right-expression);
end;

define method print-filter (filter :: <or-expression>)
  format-out("or filter: ");
  print-filter(filter.left-expression);
  print-filter(filter.right-expression);
end;

define method print-filter (filter :: <not-expression>)
  format-out("not filter: ");
  print-filter(filter.expression);
end;


