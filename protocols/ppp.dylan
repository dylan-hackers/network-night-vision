module: ppp
Author: Hannes Mehnert
Copyright: (C) 2008,  All rights reserved. Free for non-commercial use.

define protocol ppp (header-frame)
  layering field protocol :: <2byte-big-endian-unsigned-integer>;
  variably-typed-field payload,
    type-function: payload-type(frame);
end;

define abstract protocol link-control-protocol (variably-typed-container-frame)
  length frame.lcp-length * 8;
  over <ppp> #xc021;
  layering field lcp-code :: <unsigned-byte>;
  field lcp-identifier :: <unsigned-byte>;
  field lcp-length :: <2byte-big-endian-unsigned-integer>,
    fixup: byte-offset(frame-size(frame));
end;

define protocol lcp-configure-request (link-control-protocol)
  over <link-control-protocol> 1;
  repeated field configuration-option :: <lcp-option>,
    reached-end?: #f;
end;

define protocol lcp-configure-ack (link-control-protocol)
  over <link-control-protocol> 2;
  repeated field configuration-option :: <lcp-option>,
    reached-end?: #f;
end;

define protocol lcp-configure-nak (link-control-protocol)
  over <link-control-protocol> 3;
  repeated field configuration-option :: <lcp-option>,
    reached-end?: #f;
end;

define protocol lcp-configure-reject (link-control-protocol)
  over <link-control-protocol> 4;
  repeated field configuration-option :: <lcp-option>,
    reached-end?: #f;
end;

define protocol lcp-terminate-request (link-control-protocol)
  over <link-control-protocol> 5;
  field custom-data :: <raw-frame>;
end;

define protocol lcp-terminate-ack (link-control-protocol)
  over <link-control-protocol> 6;
  field custom-data :: <raw-frame>;
end;

define protocol lcp-code-reject (link-control-protocol)
  over <link-control-protocol> 7;
  field rejected-packet :: <raw-frame>; //? <link-control-protocol>;
end;

define protocol lcp-protocol-reject (link-control-protocol)
  over <link-control-protocol> 8;
  //?field rejected-packet :: <ppp>;
  field rejected-protocol :: <2byte-big-endian-unsigned-integer>;
  field rejected-information :: <raw-frame>; //? <link-control-protocol>;
end;

define protocol lcp-magic-custom (link-control-protocol)
  field magic-number :: <big-endian-unsigned-integer-4byte>;
  field custom-data :: <raw-frame>;
end;

define protocol lcp-echo-request (lcp-magic-custom)
  over <link-control-protocol> 9;
end;

define protocol lcp-echo-reply (lcp-magic-custom)
  over <link-control-protocol> 10;
end;

define protocol lcp-discard-request (lcp-magic-custom)
  over <link-control-protocol> 11;
end;

define protocol lcp-identification (link-control-protocol)
  over <link-control-protocol> 12;
  field magic-number :: <big-endian-unsigned-integer-4byte>;
  field message :: <externally-delimited-string>;
end;

define protocol lcp-time-remaining (link-control-protocol)
  over <link-control-protocol> 13;
  field magic-number :: <big-endian-unsigned-integer-4byte>;
  field seconds-remaining :: <big-endian-unsigned-integer-4byte>;
  field message :: <externally-delimited-string>;
end;

define abstract protocol lcp-option (variably-typed-container-frame)
  length frame.lcp-option-length * 8;
  layering field lcp-option-type :: <unsigned-byte>;
  field lcp-option-length :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame));
end;

define protocol lcp-reserved (lcp-option)
  over <lcp-option> 0;
end;

define protocol lcp-maximum-receive-unit (lcp-option)
  over <lcp-option> 1;
  field maximum-receive-unit :: <2byte-big-endian-unsigned-integer>;
end;

define protocol lcp-authentication-protocol (lcp-option)
  over <lcp-option> 3;
  enum field authentication-protocol :: <2byte-big-endian-unsigned-integer>,
    mappings: { #xc023 <=> #"password authentication protocol",
                #xc223 <=> #"challenge handshake authentication protocol" };
  field custom-data :: <raw-frame>;
end;

define protocol lcp-quality-protocol (lcp-option)
  over <lcp-option> 4;
  enum field quality-protocol :: <2byte-big-endian-unsigned-integer>,
    mappings: { #xc025 <=> #"link quality report" };
  field custom-data :: <raw-frame>;
end;

define protocol lcp-magic-number-option (lcp-option)
  over <lcp-option> 5;
  field lcp-magic-number :: <big-endian-unsigned-integer-4byte>;
end;

define protocol lcp-protocol-field-compression (lcp-option)
  over <lcp-option> 7;
end;

define protocol lcp-address-and-control-field-compression (lcp-option)
  over <lcp-option> 8;
end;

define protocol lcp-fcs-alternatives (lcp-option)
  over <lcp-option> 9;
  field null-fcs :: <boolean-bit>;
  field ccitt-16 :: <boolean-bit>;
  field ccitt-32 :: <boolean-bit>;
  field reserved :: <5bit-unsigned-integer> = 0;
end;

define protocol lcp-self-describing-padding (lcp-option)
  over <lcp-option> 10;
  field maximum :: <unsigned-byte>;
end;

define protocol lcp-numbered-mode (lcp-option)
  over <lcp-option> 11;
  field window :: <unsigned-byte>;
  field hdlc-address :: <raw-frame>;
end;

define protocol lcp-callback (lcp-option)
  over <lcp-option> 13;
  enum field operation :: <unsigned-byte>,
    mappings: { 0 <=> #"location by user authentication",
                1 <=> #"dialing string",
                2 <=> #"location identifier",
                3 <=> #"e.164 number",
                4 <=> #"distinguished name" };
  field message :: <raw-frame>;
end;

define protocol lcp-compound-frames (lcp-option)
  over <lcp-option> 15;
end;


define abstract protocol pap (variably-typed-container-frame)
  over <ppp> #xc023;
  length pap-length * 8;
  layering field pap-code :: <unsigned-byte>;
  field pap-identifier :: <unsigned-byte>;
  field pap-length :: <2byte-big-endian-unsigned-integer>,
    fixup: byte-offset(frame-size(frame));
end;

define protocol pap-authenticate-request (pap)
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

define protocol pap-authenticate-ack (pap)
  over <pap> 2;
  field message-length :: <unsigned-byte>,
    fixup: byte-offset(frame.message);
  field message :: <externally-delimited-string>,
    length: field.message-length * 8;
end;

define protocol pap-authenticate-nak (pap)
  over <pap> 3;
  field message-length :: <unsigned-byte>,
    fixup: byte-offset(frame.message);
  field message :: <externally-delimited-string>,
    length: field.message-length * 8;
end;

define abstract protocol chap (variably-typed-container-frame)
  over <ppp> #xc223;
  length frame.chap-length * 8;
  layering field chap-code :: <unsigned-byte>;
  field chap-identifier :: <unsigned-byte>;
  field chap-length :: <2byte-big-endian-unsigned-integer>;
end;

define protocol chap-challenge (chap)
  over <chap> 1;
  field chap-value-size :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame.chap-value));
  field chap-value :: <raw-frame>,
    length: frame.chap-value-size * 8;
  field chap-name :: <externally-delimited-string>;
end;

define protocol chap-response (chap)
  over <chap> 2;
  field chap-value-size :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame.chap-value));
  field chap-value :: <raw-frame>,
    length: frame.chap-value-size * 8;
  field chap-name :: <externally-delimited-string>;
end;

define protocol chap-success (chap)
  over <chap> 3;
  field chap-message :: <externally-delimited-string>;
end;

define protocol chap-failure (chap)
  over <chap> 4;
  field chap-message :: <externally-delimited-string>;
end;
