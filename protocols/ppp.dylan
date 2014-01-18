module: ppp
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define binary-data <ppp> (<header-frame>)
  layering field protocol :: <2byte-big-endian-unsigned-integer>;
  variably-typed field payload,
    type-function: payload-type(frame);
end;

define abstract binary-data <link-control-protocol> (<variably-typed-container-frame>)
  length frame.lcp-length * 8;
  over <ppp> #xc021;
  layering field lcp-code :: <unsigned-byte>;
  field lcp-identifier :: <unsigned-byte>;
  field lcp-length :: <2byte-big-endian-unsigned-integer>,
    fixup: byte-offset(frame-size(frame));
end;

define abstract binary-data <ip-control-protocol> (<variably-typed-container-frame>)
  length frame.ipcp-length * 8;
  over <ppp> #x8021;
  layering field ipcp-code :: <unsigned-byte>;
  field ipcp-identifier :: <unsigned-byte>;
  field ipcp-length :: <2byte-big-endian-unsigned-integer>,
    fixup: byte-offset(frame-size(frame));
end;

define macro lcp-protocol-definer
  { define lcp-protocol ?:name ("<" ## ?short:name ## ">") end }
    => {
define binary-data "<" ## ?short ## "-configure-request>" (?name)
  over ?name 1;
  repeated field configuration-options :: "<" ## ?short ## "-option>",
    reached-end?: #f;
end;

define binary-data "<" ## ?short ## "-configure-ack>" (?name)
  over ?name 2;
  repeated field configuration-options :: "<" ## ?short ## "-option>",
    reached-end?: #f;
end;

define binary-data "<" ## ?short ## "-configure-nak>" (?name)
  over ?name 3;
  repeated field configuration-options :: "<" ## ?short ## "-option>",
    reached-end?: #f;
end;

define binary-data "<" ## ?short ## "-configure-reject>" (?name)
  over ?name 4;
  repeated field configuration-options :: "<" ## ?short ## "-option>",
    reached-end?: #f;
end;

define binary-data "<" ## ?short ## "-terminate-request>" (?name)
  over ?name 5;
  field custom-data :: <raw-frame>;
end;

define binary-data "<" ## ?short ## "-terminate-ack>" (?name)
  over ?name 6;
  field custom-data :: <raw-frame>;
end;

define binary-data "<" ## ?short ## "-code-reject>" (?name)
  over ?name 7;
  field rejected-packet :: <raw-frame>; //? <link-control-protocol>;
end;

define abstract binary-data "<" ## ?short ## "-option>" (<variably-typed-container-frame>)
  length ?short ## "-option-length" (frame) * 8;
  layering field ?short ## "-option-type" :: <unsigned-byte>;
  field ?short ## "-option-length" :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame));
end;

};
end;

define lcp-protocol <link-control-protocol> (<lcp>) end;


define binary-data <lcp-protocol-reject> (<link-control-protocol>)
  over <link-control-protocol> 8;
  //?field rejected-packet :: <ppp>;
  field rejected-protocol :: <2byte-big-endian-unsigned-integer>;
  field rejected-information :: <raw-frame>; //? <link-control-protocol>;
end;

define binary-data <lcp-magic-custom> (<link-control-protocol>)
  field magic-number :: <big-endian-unsigned-integer-4byte>;
  field custom-data :: <raw-frame>;
end;

define binary-data <lcp-echo-request> (<lcp-magic-custom>)
  over <link-control-protocol> 9;
end;

define binary-data <lcp-echo-reply> (<lcp-magic-custom>)
  over <link-control-protocol> 10;
end;

define binary-data <lcp-discard-request> (<lcp-magic-custom>)
  over <link-control-protocol> 11;
end;

define binary-data <lcp-identification> (<link-control-protocol>)
  over <link-control-protocol> 12;
  field magic-number :: <big-endian-unsigned-integer-4byte>;
  field message :: <externally-delimited-string>;
end;

define binary-data <lcp-time-remaining> (<link-control-protocol>)
  over <link-control-protocol> 13;
  field magic-number :: <big-endian-unsigned-integer-4byte>;
  field seconds-remaining :: <big-endian-unsigned-integer-4byte>;
  field message :: <externally-delimited-string>;
end;


define binary-data <lcp-reserved> (<lcp-option>)
  over <lcp-option> 0;
end;

define binary-data <lcp-maximum-receive-unit> (<lcp-option>)
  over <lcp-option> 1;
  field maximum-receive-unit :: <2byte-big-endian-unsigned-integer>;
end;

define binary-data <lcp-authentication-protocol> (<lcp-option>)
  over <lcp-option> 3;
  enum field authentication-protocol :: <2byte-big-endian-unsigned-integer>,
    mappings: { #xc023 <=> #"password authentication protocol",
                #xc223 <=> #"challenge handshake authentication protocol" };
  field custom-data :: <raw-frame>;
end;

define binary-data <lcp-quality-protocol> (<lcp-option>)
  over <lcp-option> 4;
  enum field quality-protocol :: <2byte-big-endian-unsigned-integer>,
    mappings: { #xc025 <=> #"link quality report" };
  field custom-data :: <raw-frame>;
end;

define binary-data <lcp-magic-number-option> (<lcp-option>)
  over <lcp-option> 5;
  field lcp-magic-number :: <big-endian-unsigned-integer-4byte>;
end;

define binary-data <lcp-protocol-field-compression> (<lcp-option>)
  over <lcp-option> 7;
end;

define binary-data <lcp-address-and-control-field-compression> (<lcp-option>)
  over <lcp-option> 8;
end;

define binary-data <lcp-fcs-alternative> (<lcp-option>)
  over <lcp-option> 9;
  field null-fcs :: <boolean-bit>;
  field ccitt-16 :: <boolean-bit>;
  field ccitt-32 :: <boolean-bit>;
  field reserved :: <5bit-unsigned-integer> = 0;
end;

define binary-data <lcp-self-describing-padding> (<lcp-option>)
  over <lcp-option> 10;
  field maximum :: <unsigned-byte>;
end;

define binary-data <lcp-numbered-mode> (<lcp-option>)
  over <lcp-option> 11;
  field window :: <unsigned-byte>;
  field hdlc-address :: <raw-frame>;
end;

define binary-data <lcp-callback> (<lcp-option>)
  over <lcp-option> 13;
  enum field operation :: <unsigned-byte>,
    mappings: { 0 <=> #"location by user authentication",
                1 <=> #"dialing string",
                2 <=> #"location identifier",
                3 <=> #"e.164 number",
                4 <=> #"distinguished name" };
  field message :: <raw-frame>;
end;

define binary-data <lcp-compound-frames> (<lcp-option>)
  over <lcp-option> 15;
end;


define abstract binary-data <pap> (<variably-typed-container-frame>)
  over <ppp> #xc023;
  length pap-length * 8;
  layering field pap-code :: <unsigned-byte>;
  field pap-identifier :: <unsigned-byte>;
  field pap-length :: <2byte-big-endian-unsigned-integer>,
    fixup: byte-offset(frame-size(frame));
end;

define binary-data <pap-authenticate-request> (<pap>)
  over <pap> 1;
  field peer-id-length :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame.peer-id));
  field peer-id :: <externally-delimited-string>,
    length: frame.peer-id-length * 8;
  field password-length :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame.password));
  field password :: <raw-frame>,
    length: frame.password-length * 8;
end;

define binary-data <pap-authenticate-ack> (<pap>)
  over <pap> 2;
  field message-length :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame.message));
  field message :: <externally-delimited-string>,
    length: frame.message-length * 8;
end;

define binary-data <pap-authenticate-nak> (<pap>)
  over <pap> 3;
  field message-length :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame.message));
  field message :: <externally-delimited-string>,
    length: frame.message-length * 8;
end;

define abstract binary-data <chap> (<variably-typed-container-frame>)
  over <ppp> #xc223;
  length frame.chap-length * 8;
  layering field chap-code :: <unsigned-byte>;
  field chap-identifier :: <unsigned-byte>;
  field chap-length :: <2byte-big-endian-unsigned-integer>,
    fixup: byte-offset(frame-size(frame));
end;

define binary-data <chap-challenge> (<chap>)
  over <chap> 1;
  field chap-value-size :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame.chap-value));
  field chap-value :: <raw-frame>,
    length: frame.chap-value-size * 8;
  field chap-name :: <externally-delimited-string>;
end;

define binary-data <chap-response> (<chap>)
  over <chap> 2;
  field chap-value-size :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame.chap-value));
  field chap-value :: <raw-frame>,
    length: frame.chap-value-size * 8;
  field chap-name :: <externally-delimited-string>;
end;

define binary-data <chap-success> (<chap>)
  over <chap> 3;
  field chap-message :: <externally-delimited-string>;
end;

define binary-data <chap-failure> (<chap>)
  over <chap> 4;
  field chap-message :: <externally-delimited-string>;
end;

define lcp-protocol <ip-control-protocol> (<ipcp>) end;

define binary-data <ipcp-ip-addresses> (<ipcp-option>)
  over <ipcp-option> 1;
  field source-ip-address :: <ipv4-address>;
  field destination-ip-address :: <ipv4-address>;
end;

define binary-data <ipcp-ip-compression-protocol> (<ipcp-option>)
  over <ipcp-option> 2;
  enum field compression-protocol :: <2byte-big-endian-unsigned-integer>,
    mappings: { #x002d <=> #"van jacobsen compressed TCP/IP" };
  field max-slot-id :: <unsigned-byte>;
  enum field compress-slot-id :: <unsigned-byte>,
    mappings: { 0 <=> #"not compressed",
                1 <=> #"compressed" };
  field custom-data :: <raw-frame>;
end;

define binary-data <ipcp-ip-address> (<ipcp-option>)
  over <ipcp-option> 3;
  field ip-address :: <ipv4-address>;
end;

define binary-data <ipcp-mobile-ipv4> (<ipcp-option>)
  over <ipcp-option> 4;
  field mobile-nodes-home-address :: <ipv4-address>;
end;

define binary-data <ipcp-primary-dns> (<ipcp-option>)
  over <ipcp-option> 129;
  field primary-dns :: <ipv4-address>;
end;

define binary-data <ipcp-primary-nbns> (<ipcp-option>)
  over <ipcp-option> 130;
  field primary-nbnd :: <ipv4-address>;
end;

define binary-data <ipcp-secondary-dns> (<ipcp-option>)
  over <ipcp-option> 131;
  field secondary-dns :: <ipv4-address>;
end;

define binary-data <ipcp-secondary-nbns> (<ipcp-option>)
  over <ipcp-option> 132;
  field secondary-nbns :: <ipv4-address>;
end;

