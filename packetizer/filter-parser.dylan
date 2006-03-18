module: packet-filter
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define function extract-action
    (token-string :: <byte-string>,
     token-start :: <integer>, 	 
     token-end :: <integer>) 	 
 => (result :: <byte-string>); 	 
  copy-sequence(token-string, start: token-start, end: token-end);
end;


define constant $filter-tokens
  = simple-lexical-definition
      inert "([ \t]+)";

      token EOF;
      token AMP = "&";
      token PIPE = "\\|";
      token TILDE = "~";
      token EQUALS = "=";
      token DOT = "\\.";
      token LPAREN = "\\(";
      token RPAREN = "\\)";
      token COLON = ":";

      token Name = "[a-zA-Z_0-9-]+",
         semantic-value-function: extract-action;
end;

define constant $filter-productions
 = simple-grammar-productions
  production value => [Name value], action:
    method(p :: <simple-parser>, data, s, e)
        concatenate(p[0], p[1]);
    end;

  production value => [DOT value], action:
    method(p :: <simple-parser>, data, s, e)
        concatenate(".", p[1]);
    end;
  production value => [COLON value], action:
    method(p :: <simple-parser>, data, s, e)
        concatenate(":", p[1]);
    end;

  production value => [], action:
    method(p :: <simple-parser>, data, s, e)
        "";
    end;

  production filter => [LPAREN filter RPAREN AMP LPAREN filter RPAREN], action:
    method(p :: <simple-parser>, data, s, e)
        make(<and-expression>, left: p[1], right: p[5]);
    end;

  production filter => [LPAREN filter RPAREN PIPE LPAREN filter RPAREN], action:
    method(p :: <simple-parser>, data, s, e)
        make(<or-expression>, left: p[1], right: p[5]);
    end;

  production filter => [TILDE LPAREN filter RPAREN], action:
    method(p :: <simple-parser>, data, s, e)
        make(<not-expression>, left: p[2]);
    end;

  production filter => [Name], action:
    method(p :: <simple-parser>, data, s, e)
        make(<frame-present>, frame: as(<symbol>, p[0]));
    end;

  production filter => [Name DOT Name EQUALS value], action:
    method(p :: <simple-parser>, data, s, e)
        make(<field-equals>,
             frame: as(<symbol>, p[0]),
             name: as(<symbol>, p[2]),
             value: p[4]); //read-frame(<ipv4-address>, p[4]));
    end;

  production compound-filter => [filter], action:
    method(p :: <simple-parser>, data, s, e)
        data.filter := p[0];
    end;
end;

define constant $filter-automaton
  = simple-parser-automaton($filter-tokens, $filter-productions,
                            #[#"compound-filter"]);

define function consume-token 	 
    (consumer-data,
     token-number :: <integer>,
     token-name :: <object>,
     semantic-value :: <object>,
     start-position :: <integer>,
     end-position :: <integer>)
 => ();
  //let srcloc
  //  = range-source-location(consumer-data, start-position, end-position);
  format-out("%d - %d: token %d: %= value %=\n",
             start-position,
             end-position,
             token-number,
             token-name,
             semantic-value);
end function;

define class <filter> (<object>)
  slot filter :: <filter-expression>
end;

define function parse-filter (input :: <string>)
  let rangemap = make(<source-location-rangemap>);
  let scanner = make(<simple-lexical-scanner>,
                     definition: $filter-tokens,
                     rangemap: rangemap);
  let data = make(<filter>);
  let parser = make(<simple-parser>,
                    automaton: $filter-automaton,
                    start-symbol: #"compound-filter",
                    rangemap: rangemap,
                    consumer-data: data);
  scan-tokens(scanner,
              simple-parser-consume-token,
//              consume-token,
              parser,
              input,
              end: input.size,
              partial?: #f);
  scan-tokens(scanner, simple-parser-consume-token, parser, "", partial?: #f);
  let end-position = scanner.scanner-source-position;
  simple-parser-consume-token(parser, 0, #"EOF", parser, end-position, end-position);
  data.filter;
end;

define method print-object (filter :: <frame-present>, stream :: <stream>) => ();
  format(stream, "%s", filter.frame-name);
end;

define method print-object (filter :: <field-equals>, stream :: <stream>) => ();
  format(stream,
         "%s.%s = %s",
         filter.frame-name,
         filter.field-name,
         filter.field-value);
end;

define method print-object (filter :: <and-expression>, stream :: <stream>) => ();
  format(stream, "(%=) & (%=)", filter.left-expression, filter.right-expression);
end;

define method print-object (filter :: <or-expression>, stream :: <stream>) => ();
  format(stream, "(%=) | (%=)", filter.left-expression, filter.right-expression);
end;

define method print-filter (filter :: <not-expression>, stream :: <stream>) => ();
  format(stream, "~ (%=)", filter.expression);
end;

define function test-filter()
  format-out("%=\n",
             parse-filter("(ip.source-address = 23.23.23.23) & ((tcp.source-port = 23) & (foo))"));
end;

