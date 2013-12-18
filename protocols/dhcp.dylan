module: dhcp
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

//from rfc2131
define binary-data dhcp-message (container-frame)
  over <udp-frame> 67;
  enum field operation :: <unsigned-byte> = 1,
    mappings: { 1 <=> #"bootrequest",
                2 <=> #"bootreply" };
  field hardware-address-type :: <unsigned-byte> = 1;
  field hardware-address-length :: <unsigned-byte> = 6;
  field hops :: <unsigned-byte> = 0;
  field transaction-id :: <big-endian-unsigned-integer-4byte>;
  field seconds-since-address-acquisition
    :: <2byte-big-endian-unsigned-integer> = 0;
  field broadcast-flag :: <1bit-unsigned-integer> = 0;
  field reserved :: <15bit-unsigned-integer> = 0;
  field client-ip-address :: <ipv4-address> = ipv4-address("0.0.0.0");
  field your-ip-address :: <ipv4-address> = ipv4-address("0.0.0.0");
  field server-ip-address :: <ipv4-address> = ipv4-address("0.0.0.0");
  field relay-agent-ip-address :: <ipv4-address> = ipv4-address("0.0.0.0");
  field client-hardware-address :: <raw-frame> = $empty-raw-frame,
    static-length: 16 * 8;
  field server-name :: <externally-delimited-string>
    = $empty-externally-delimited-string,
    static-length: 64 * 8;
  field boot-file-name :: <externally-delimited-string>
    = $empty-externally-delimited-string,
    static-length: 128 * 8;
  field magic-cookie :: <big-endian-unsigned-integer-4byte>
    = big-endian-unsigned-integer-4byte(#(#x63, #x82, #x53, #x63));
  repeated field dhcp-options :: <dhcp-option>,
    reached-end?: instance?(frame, <dhcp-end-option>);
end;

define abstract binary-data dhcp-option (variably-typed-container-frame)
  layering field option-code :: <unsigned-byte>;
end;

//from rfc2132
define binary-data dhcp-pad-option (dhcp-option)
  over <dhcp-option> 0;
end;

define binary-data dhcp-end-option (dhcp-option)
  over <dhcp-option> 255;
end;

define abstract binary-data dhcp-option-with-data (dhcp-option)
  length (frame.option-length + 2) * 8;
  field option-length :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame)) - 2;
end;

define binary-data dhcp-subnet-mask (dhcp-option-with-data)
  over <dhcp-option> 1;
  summary "%=", subnet-mask;
  field subnet-mask :: <ipv4-address>;
end;

define binary-data dhcp-time-offset (dhcp-option-with-data)
  over <dhcp-option> 2;
  field time-offset :: <big-endian-unsigned-integer-4byte>;
end;

define abstract binary-data dhcp-option-with-addresses (dhcp-option-with-data)
  repeated field addresses :: <ipv4-address>, reached-end?: #f;
end;

define binary-data dhcp-router-option (dhcp-option-with-addresses)
  over <dhcp-option> 3;
end;

define binary-data dhcp-time-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 4;
end;

define binary-data dhcp-name-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 5;
end;

define binary-data dhcp-domain-name-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 6;
end;

define binary-data dhcp-log-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 7;
end;

define binary-data dhcp-cookie-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 8;
end;

define binary-data dhcp-lpr-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 9;
end;

define binary-data dhcp-impress-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 10;
end;

define binary-data dhcp-resource-location-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 11;
end;

define binary-data dhcp-host-name-option (dhcp-option-with-data)
  over <dhcp-option> 12;
  field host-name :: <externally-delimited-string>;
end;

define binary-data dhcp-boot-file-size-option (dhcp-option-with-data)
  over <dhcp-option> 13;
  field file-length :: <2byte-big-endian-unsigned-integer>; /* number of 512 octet-blocks */
end;

define binary-data dhcp-merit-dump-file-option (dhcp-option-with-data)
  over <dhcp-option> 14;
  field dump-file-pathname :: <externally-delimited-string>;
end;

define binary-data dhcp-domain-name (dhcp-option-with-data)
  over <dhcp-option> 15;
  field domain-name :: <externally-delimited-string>;
end;

define binary-data dhcp-swap-server (dhcp-option-with-data)
  over <dhcp-option> 16;
  field swap-server-address :: <ipv4-address>;
end;

define binary-data dhcp-root-path (dhcp-option-with-data)
  over <dhcp-option> 17;
  field root-disk-pathname :: <externally-delimited-string>;
end;

define binary-data dhcp-extensions-path (dhcp-option-with-data)
  over <dhcp-option> 18;
  field extensions-pathname :: <externally-delimited-string>;
end;

define abstract binary-data dhcp-boolean-option (dhcp-option-with-data)
  field option-enabled :: <unsigned-byte>
end;
define binary-data dhcp-ip-forwarding-option (dhcp-boolean-option)
  over <dhcp-option> 19;
end;

define binary-data dhcp-non-local-source-routing-option (dhcp-boolean-option)
  over <dhcp-option> 20;
end;

define binary-data dhcp-policy-filter-option (dhcp-option-with-data)
  over <dhcp-option> 21;
  repeated field address-masks :: <address-mask>, reached-end?: #f;
end;

define binary-data address-mask (container-frame)
  field address :: <ipv4-address>;
  field mask :: <ipv4-address>;
end;

define binary-data dhcp-maximum-datagram-reassembly-size (dhcp-option-with-data)
  over <dhcp-option> 22;
  field reassembly-size :: <2byte-big-endian-unsigned-integer>;
end;

define binary-data dhcp-ip-ttl-option (dhcp-option-with-data)
  over <dhcp-option> 23;
  field time-to-live :: <unsigned-byte>;
end;

define binary-data dhcp-path-mtu-aging-timeout-option (dhcp-option-with-data)
  over <dhcp-option> 24;
  field mtu-aging-timeout :: <big-endian-unsigned-integer-4byte>;
end;

define binary-data dhcp-path-mtu-plateau-table-option (dhcp-option-with-data)
  over <dhcp-option> 25;
  repeated field mtu-sizes :: <2byte-big-endian-unsigned-integer>,
    reached-end?: #f;
end;

define binary-data dhcp-interface-mtu-option (dhcp-option-with-data)
  over <dhcp-option> 26;
  field interface-mtu :: <2byte-big-endian-unsigned-integer>;
end;

define binary-data dhcp-all-subnets-are-local-option (dhcp-option-with-data)
  over <dhcp-option> 27;
  field all-subnets-are-local :: <unsigned-byte>;
end;

define binary-data dhcp-broadcast-address-option (dhcp-option-with-data)
  over <dhcp-option> 28;
  field broadcast-address :: <ipv4-address>;
end;

define binary-data dhcp-perform-mask-discovery-option (dhcp-boolean-option)
  over <dhcp-option> 29;
end;

define binary-data dhcp-mask-supplier-option (dhcp-boolean-option)
  over <dhcp-option> 30;
end;

define binary-data dhcp-perform-router-discovery-option (dhcp-boolean-option)
  over <dhcp-option> 31;
end;

define binary-data dhcp-router-solicitation-address-option (dhcp-option-with-data)
  over <dhcp-option> 32;
  field router-solicitation-address :: <ipv4-address>;
end;

define binary-data dhcp-static-route-option (dhcp-option-with-data)
  over <dhcp-option> 33;
  repeated field destination-routers :: <destination-router>, reached-end?: #f;
end;

define binary-data destination-router (container-frame)
  field destination :: <ipv4-address>;
  field router :: <ipv4-address>;
end;

define binary-data dhcp-trailer-encapsulation-option (dhcp-boolean-option)
  over <dhcp-option> 34;
end;

define binary-data dhcp-arp-cache-timeout-option (dhcp-option-with-data)
  over <dhcp-option> 35;
  field arp-timeout :: <big-endian-unsigned-integer-4byte>;
end;

define binary-data dhcp-ethernet-encapsulation-option (dhcp-boolean-option)
  over <dhcp-option> 36;
end;

define binary-data dhcp-tcp-default-ttl-option (dhcp-option-with-data)
  over <dhcp-option> 37;
  field time-to-live :: <unsigned-byte>;
end;

define binary-data dhcp-tcp-keepalive-interval-option (dhcp-option-with-data)
  over <dhcp-option> 38;
  field keepalive-time :: <big-endian-unsigned-integer-4byte>;
end;

define binary-data dhcp-tcp-keepalive-garbage-option (dhcp-boolean-option)
  over <dhcp-option> 39;
end;

define binary-data dhcp-nis-domain-name-option (dhcp-option-with-data)
  over <dhcp-option> 40;
  field nis-domain-name :: <externally-delimited-string>;
end;

define binary-data dhcp-nis-servers-option (dhcp-option-with-addresses)
  over <dhcp-option> 41;
end;

define binary-data dhcp-ntp-servers-option (dhcp-option-with-addresses)
  over <dhcp-option> 42;
end;

define binary-data dhcp-vendor-specific-option (dhcp-option-with-data)
  over <dhcp-option> 43;
  repeated field vendor-specific-options :: <dhcp-vendor-specific>, reached-end?: #f;
end;

define binary-data dhcp-vendor-specific (container-frame)
  field vendor-specific-code :: <unsigned-byte>;
  field option-length :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame.data-bytes));
  field data-bytes :: <raw-frame>, length: frame.option-length * 8;
end;

define binary-data dhcp-netbios-name-servers-option (dhcp-option-with-addresses)
  over <dhcp-option> 44;
end;

define binary-data dhcp-netbios-datagram-distribution-servers-option (dhcp-option-with-addresses)
  over <dhcp-option> 45;
end;

define binary-data dhcp-netbios-node-type-option (dhcp-option-with-data)
  over <dhcp-option> 46;
  enum field node-type :: <unsigned-byte>,
    mappings: { #x1 <=> #"b-node",
                #x2 <=> #"p-node",
                #x4 <=> #"m-node",
                #x8 <=> #"h-node" };
end;

define binary-data dhcp-netbios-scope-option (dhcp-option-with-data)
  over <dhcp-option> 47;
  field scope :: <raw-frame>;
end;

define binary-data dhcp-x-window-system-font-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 48;
end;

define binary-data dhcp-x-window-system-display-manager-option (dhcp-option-with-addresses)
  over <dhcp-option> 49;
end;

define binary-data dhcp-nis+-domain-option (dhcp-option-with-data)
  over <dhcp-option> 64;
  field nis-client-domain-name :: <externally-delimited-string>;
end;

define binary-data dhcp-nis+-servers-option (dhcp-option-with-addresses)
  over <dhcp-option> 65;
end;

define binary-data dhcp-mobile-ip-home-agent-option (dhcp-option-with-addresses)
  over <dhcp-option> 68;
end;

define binary-data dhcp-smtp-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 69;
end;

define binary-data dhcp-pop3-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 70;
end;

define binary-data dhcp-nntp-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 71;
end;

define binary-data dhcp-www-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 72;
end;

define binary-data dhcp-finger-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 73;
end;

define binary-data dhcp-irc-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 74;
end;

define binary-data dhcp-streettalk-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 75;
end;

define binary-data dhcp-streettalk-directory-assistance-server-option (dhcp-option-with-addresses)
  over <dhcp-option> 76;
end;

define binary-data dhcp-requested-ip-address-option (dhcp-option-with-data)
  over <dhcp-option> 50;
  field requested-ip :: <ipv4-address>;
end;

define binary-data dhcp-address-lease-time-option (dhcp-option-with-data)
  over <dhcp-option> 51;
  field ip-lease-time :: <big-endian-unsigned-integer-4byte>;
end;

define binary-data dhcp-option-overload-option (dhcp-option-with-data)
  over <dhcp-option> 52;
  field overloaded-fields :: <unsigned-byte>;
//1 -> file; 2 -> sname; 3 -> both
end;

define binary-data dhcp-tftp-server-name-option (dhcp-option-with-data)
  over <dhcp-option> 66;
  summary "%=", tftp-server-name;
  field tftp-server-name :: <externally-delimited-string>;
end;

define binary-data dhcp-bootfile-name-option (dhcp-option-with-data)
  over <dhcp-option> 67;
  field bootfile-name :: <externally-delimited-string>;
end;

define binary-data dhcp-message-type-option (dhcp-option-with-data)
  over <dhcp-option> 53;
  summary "%=", message-type;
  enum field message-type :: <unsigned-byte>,
    mappings: { 1 <=> #"dhcpdiscover",
                2 <=> #"dhcpoffer",
                3 <=> #"dhcprequest",
                4 <=> #"dhcpdecline",
                5 <=> #"dhcpack",
                6 <=> #"dhcpnak",
                7 <=> #"dhcprelease",
                8 <=> #"dhcpinform" };
end;

define binary-data dhcp-server-identifier-option (dhcp-option-with-data)
  over <dhcp-option> 54;
  summary "%=", selected-server;
  field selected-server :: <ipv4-address>;
end;

define binary-data dhcp-parameter-request-list-option (dhcp-option-with-data)
  over <dhcp-option> 55;
  repeated field requested-options :: <unsigned-byte>, reached-end?: #f;
end;

define binary-data dhcp-message-option (dhcp-option-with-data)
  over <dhcp-option> 56;
  field message-text :: <externally-delimited-string>;
end;

define binary-data dhcp-maximum-message-size-option (dhcp-option-with-data)
  over <dhcp-option> 57;
  field message-size :: <2byte-big-endian-unsigned-integer>;
end;

define binary-data dhcp-renewal-time-value-option (dhcp-option-with-data)
  over <dhcp-option> 58;
  field renewal-time :: <big-endian-unsigned-integer-4byte>;
end;

define binary-data dhcp-rebinding-time-value-option (dhcp-option-with-data)
  over <dhcp-option> 59;
  field rebinding-time :: <big-endian-unsigned-integer-4byte>;
end;

define binary-data dhcp-vendor-class-identifier-option (dhcp-option-with-data)
  over <dhcp-option> 60;
  field vendor-class-identifier :: <raw-frame>;
end;

define binary-data dhcp-client-identifier (dhcp-option-with-data)
  over <dhcp-option> 61;
  field hardware-type :: <unsigned-byte>;
  field client-identifier :: <raw-frame>;
end;

//rfc2242
define binary-data dhcp-netware-domain-name-option (dhcp-option-with-data)
  over <dhcp-option> 62;
  field netware-domain-name :: <externally-delimited-string>;
end;

define binary-data dhcp-netware-ip-option (dhcp-option-with-data)
  over <dhcp-option> 63;
  field options :: <raw-frame>;
end;

//rfc4676
define binary-data dhcp-geoconf-civic-option (dhcp-option-with-data)
  over <dhcp-option> 99;
  field what :: <unsigned-byte>;
  field country-code :: <externally-delimited-string>, static-length: 2 * 8;
  field civic-address-elements :: <raw-frame>;
end;

//rfc4702
define binary-data dhcp-fully-qualified-host-name-option (dhcp-option-with-data)
  over <dhcp-option> #x51;
  field reserverd :: <4bit-unsigned-integer>;
  field do-any-dns-update? :: <1bit-unsigned-integer>;
  field encoding? :: <1bit-unsigned-integer>;
  field override-s? :: <1bit-unsigned-integer>;
  field update-dns-rr? :: <1bit-unsigned-integer>;
  field response-code1 :: <unsigned-byte>;
  field response-code2 :: <unsigned-byte>;
  field domain-name :: <externally-delimited-string>;
end;
