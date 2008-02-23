module: socks
author: Hannes Mehnert

//rfc1928
define protocol socks5-version/method-selection (container-frame)
  field version-number :: <unsigned-byte> = 5;
  field number-methods :: <unsigned-byte>,
    fixup: frame.methods.size;
  repeated field methods :: <unsigned-byte>,
    count: frame.number-methods;
end;

define protocol socks5-version-selection (container-frame)
  field version-number :: <unsigned-byte> = 5;
  field method-to-use :: <unsigned-byte>;
end;

/*
current methods:
o  X'00' NO AUTHENTICATION REQUIRED
o  X'01' GSSAPI
o  X'02' USERNAME/PASSWORD
o  X'03' to X'7F' IANA ASSIGNED
o  X'80' to X'FE' RESERVED FOR PRIVATE METHODS
o  X'FF' NO ACCEPTABLE METHODS
*/

define protocol socks5-request (container-frame)
  field version-number :: <unsigned-byte> = 5;
  enum field command :: <unsigned-byte> = 0,
    mappings: { 1 <=> #"connect",
                2 <=> #"bind",
                3 <=> #"udp associate" };
  field reserved :: <unsigned-byte> = 0;
  enum field address-type :: <unsigned-byte>,
    mappings: { 1 <=> #"ipv4 address",
                3 <=> #"domainname",
                4 <=> #"ipv6 address" };
  variably-typed-field bind-address, type-function:
    if (frame.address-type == #"ipv4 address")
      <ipv4-address>
    elseif (frame.address-type == #"domainname")
      <domain-name>
    elseif (frame.address-type == #"ipv6 address")
      <ipv6-address>
    end;
  field bind-port :: <2byte-big-endian-unsigned-integer>;
end;


define protocol socks5-reply (container-frame)
  field version-number :: <unsigned-byte> = 5;
  enum field reply-field :: <unsigned-byte> = 0,
    mappings: { 0 <=> #"succeeded",
                1 <=> #"general SOCKS server failure",
                2 <=> #"connection not allowed by ruleset",
                3 <=> #"Network unreachable",
                4 <=> #"Host unreachable",
                5 <=> #"Connection refused",
                6 <=> #"TTL expired",
                7 <=> #"Command not supported",
                8 <=> #" Address type not supported" };
  field reserved :: <unsigned-byte> = 0;
  enum field address-type :: <unsigned-byte>,
    mappings: { 1 <=> #"ipv4 address",
                3 <=> #"domainname",
                4 <=> #"ipv6 address" };
  variably-typed-field bind-address, type-function:
    if (frame.address-type == #"ipv4 address")
      <ipv4-address>
    elseif (frame.address-type == #"domainname")
      <domain-name>
    elseif (frame.address-type == #"ipv6 address")
      <ipv6-address>
    end;
  field bind-port :: <2byte-big-endian-unsigned-integer>;
end;

define protocol socks5-udp-associate (container-frame)
  field reserved :: <2byte-big-endian-unsigned-integer> = 0;
  field fragment-number :: <unsigned-byte> = 0;
  enum field address-type :: <unsigned-byte>,
    mappings: { 1 <=> #"ipv4 address",
                3 <=> #"domainname",
                4 <=> #"ipv6 address" };
  variably-typed-field destination-address, type-function:
    if (frame.address-type == #"ipv4 address")
      <ipv4-address>
    elseif (frame.address-type == #"domainname")
      <domain-name>
    elseif (frame.address-type == #"ipv6 address")
      <ipv6-address>
    end;
  field destination-port :: <2byte-big-endian-unsigned-integer>;
  field user-data :: <raw-frame>;
end;

define protocol null-terminated-string (container-frame)
  repeated field characters :: <unsigned-byte>,
    reached-end?: frame == 0;
end;

define protocol socks4-connection-request (container-frame)
  field version-number :: <unsigned-byte> = 4;
  enum field command-code :: <unsigned-byte> = 1,
    mappings: { 1 <=> #"TCP/IP stream connection",
                2 <=> #"TCP/IP port binding" };
  field port-number :: <2byte-big-endian-unsigned-integer> = 0;
  field ip-address :: <ipv4-address>;
  field user-id :: <null-terminated-string>;
end;

define protocol socks4-response (container-frame)
  field null-byte :: <unsigned-byte> = 0;
  enum field status :: <unsigned-byte>,
    mappings: { #x5a <=> #"request granted",
                #x5b <=> #"request rejected or failed",
                #x5c <=> #"request failed, client has no identd",
                #x5d <=> #"request failed, clients identd no confirmation" };
  field arbitrary-bytes-1 :: <2byte-big-endian-unsigned-integer> = 0;
  field arbitrary-bytes-2 :: <big-endian-unsigned-integer-4byte>;
end;

define protocol socks4a-connection-request (socks4-connection-request)
  field domain-name :: <null-terminated-string>;
end;

define protocol socks4a-response (container-frame)
  field null-byte :: <unsigned-byte> = 0;
  enum field status :: <unsigned-byte>,
    mappings: { #x5a <=> #"request granted",
                #x5b <=> #"request rejected or failed",
                #x5c <=> #"request failed, client has no identd",
                #x5d <=> #"request failed, clients identd no confirmation" };
  field port-number :: <2byte-big-endian-unsigned-integer> = 0;
  field ip-address :: <ipv4-address>;
end;

