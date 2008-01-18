module: dylan-user

define library protocols
  use common-dylan;
  use system;
  use packetizer;
  use io;
  use dylan;
  export logical-link,
    ethernet,
    pcap,
    ipv4,
    ipv6,
    tcp,
    icmp,
    dhcp,
    prism2,
    dns,
    rip,
    cidr,
    ieee80211;
end;

define module logical-link
  use dylan;
  use packetizer;

  export <link-control>,
    dsap, dsap-setter,
    ssap, ssap-setter,
    control, control-setter,
    organisation-code, organisation-code-setter,
    type-code, type-code-setter;
end;

define module ethernet
  use common-dylan;
  use packetizer;

  use common-extensions;

  export <ethernet-frame>,
    type-code, type-code-setter;

  export <mac-address>, mac-address;
end;

define module ieee80211
  use dylan;
  use packetizer;

  use ethernet, import: { <mac-address> };
  use logical-link, import: { <link-control> };

  export <ieee80211-frame>;
/*
  export <ieee80211-sequence-control>,
    sequence-number, sequence-number-setter,
    fragment-number, fragment-number-setter;

  export <ieee80211-capability-information>,
    reserved, reserved-setter,
    privacy, privacy-setter,
    cf-poll-request, cf-poll-request-setter,
    cl-pollable, cf-pollable-setter,
    ibss, ibss-setter,
    ess, ess-setter;

  export <ieee80211-information-field>,
    length, length-setter;

  export <ieee80211-raw-information-field>,
    data, data-setter;

  export <ieee80211-ssid>,
    data, data-setter;

  export <ieee80211-fh-set>,
    <ieee80211-ds-set>,
    <ieee80211-cf-set>,
    <ieee80211-tim>,
    <ieee80211-ibss>,
    <ieee80211-challenge-text>,
    <ieee80211-supported-rates>,
    supported-rate, supported-rate-setter;

  export <rate>,
    bss-basic-set?, bss-basic-set?-setter,
    real-rate, real-rate-setter;

  export <basic-set-rate>,
    <extended-rate>;

  export <ieee80211-reserved-field>,
    <ieee80211-information-field>,
    element-id, element-id-setter,
    information-field, information-field-setter;

  export <ieee80211-management-frame>,
   duration, duration-setter,
   bssid, bssid-setter,
   sequence-control, sequence-control-setter;

  export <ieee80211-disassociation>,
    reason-code, reason-code-setter;

  export <ieee80211-association-request>,
    capability-information, capability-information-setter,
    listen-interval, listen-interval-setter,
    ssid, ssid-setter,
    supported-rates, supported-rates-setter;

  export <ieee80211-association-response>,
    ca
*/
end;

define module prism2
  use dylan;
  use packetizer;
  use ieee80211;

  export <prism2-header-item>,
    item-did, item-did-setter,
    item-status, item-status-setter,
    item-length, item-length-setter,
    item-data, item-data-setter;

  export <prism2-frame>,
    message-code, message-code-setter,
    message-len, message-len-setter,
    device-name, device-name-setter,
    host-time, host-time-setter,
    mac-time, mac-time-setter,
    channel, channel-setter,
    rssi, rssi-setter,
    sq, sq-setter,
    signal-level, signal-level-setter,
    noise-level, noise-level-setter,
    rate, rate-setter,
    istx, istx-setter,
    frame-length, frame-length-setter;

  export <bsd-80211-radio-frame>,
    version, version-setter,
    pad, pad-setter,
    frame-length, frame-length-setter,
    it-present, it-present-setter,
    options, options-setter;

end;

define module pcap
  use dylan;
  use packetizer;
  use date;

  use ethernet, import: { <ethernet-frame> };
  use prism2, import: { <prism2-frame>, <bsd-80211-radio-frame> };

  export <pcap-file-header>,
    magic, magic-setter,
    major-version, major-version-setter,
    minor-version, minor-version-setter,
    timezone-offset, timezone-offset-setter,
    sigfigs, sigfigs-setter,
    snap-length, snap-length-setter,
    linktype, linktype-setter;

  export <pcap-packet>,
    timestamp, timestamp-setter,
    capture-length, capture-length-setter,
    packet-length, packet-length-setter;

  export <pcap-file>,
    header, header-setter,
    packets, packets-setter;

  export make-unix-time, decode-unix-time;

  export <unix-time-value>,
    seconds, seconds-setter,
    microseconds, microseconds-setter;

end;

define module ipv4
  use common-dylan, exclude: { format-to-string };
  use packetizer;
  use streams-protocol;
  use format;

  use ethernet, import: { <ethernet-frame>, <mac-address> };
  use logical-link, import: { <link-control> };

  export <ip-option-frame>,
    copy-flag, copy-flag-setter,
    option-type, option-type-setter;

  export <router-alert-ip-option>,
    router-alert-length, router-alert-length-setter,
    router-alert-value, router-alert-value-setter;

  export <end-of-option-ip-option>;

  export <no-operation-ip-option>;

  export <security-ip-option-frame>,
    security-length, security-length-setter,
    security, security-setter,
    compartments, compartments-setter,
    handling-restrictions, handling-restrictions-setter,
    transmission-control-code, transmission-control-code-setter;

  export <ipv4-address>, ipv4-address;

  export <ipv4-frame>,
    version, version-setter,
    header-length, header-length-setter,
    type-of-service, type-of-service-setter,
    total-length, total-length-setter,
    identification, identification-setter,
    evil, evil-setter,
    dont-fragment, dont-fragment-setter,
    more-fragments, more-fragments-setter,
    fragment-offset, fragment-offset-setter,
    time-to-live, time-to-live-setter,
    protocol, protocol-setter,
    header-checksum, header-checksum-setter,
    options, options-setter;

  export <udp-frame>,
    source-port, source-port-setter,
    destination-port, destination-port-setter,
    payload-size, payload-size-setter,
    checksum, checksum-setter;

  export <arp-frame>,
    mac-address-type, mac-address-type-setter,
    protocol-address-type, protocol-address-type-setter,
    mac-address-size, mac-address-size-setter,
    protocol-address-size, protocol-address-size-setter,
    operation, operation-setter,
    source-mac-address, source-mac-address-setter,
    source-ip-address, source-ip-address-setter,
    target-mac-address, target-mac-address-setter,
    target-ip-address, target-ip-address-setter;

  export calculate-checksum;
end;

define module ipv6
  use common-dylan, exclude: { format-to-string };
  use packetizer;
  use streams-protocol;
  use format;

  use ethernet, import: { <ethernet-frame>, <mac-address> };
  use logical-link, import: { <link-control> };

  export <ipv6-frame>;
end;

define module tcp
  use common-dylan, exclude: { format-to-string };
  use packetizer;
  use streams-protocol;
  use format;
  use ipv4, import: { <ipv4-frame>, <ipv4-address>, calculate-checksum };
  use ipv6, import: { <ipv6-frame> };

  export <pseudo-header>,
    reserved, reserved-setter,
    protocol, protocol-setter,
    segment-length, segment-length-setter,
    pseudo-header-data, pseudo-header-data-setter;

  export <tcp-frame>,
    source-port, source-port-setter,
    destination-port, destination-port-setter,
    sequence-number, sequence-number-setter,
    acknowledgement-number, acknowledgement-number-setter,
    data-offset, data-offset-setter,
    reserved, reserved-setter,
    urg, urg-setter,
    ack, ack-setter,
    psh, psh-setter,
    rst, rst-setter,
    syn, syn-setter,
    fin, fin-setter,
    window, window-setter,
    checksum, checksum-setter,
    urgent-pointer, urgent-pointer-setter,
    options-and-padding, options-and-padding-setter;
end;

define module icmp
  use common-dylan, exclude: { format-to-string };
  use packetizer;
  use streams-protocol;
  use format;

  use ipv4, import: { <ipv4-frame>, calculate-checksum };
  use ipv6, import: { <ipv6-frame> };

  export <icmp-frame>, icmp-frame,
    icmp-type, icmp-type-setter,
    code, code-setter,
    checksum, checksum-setter;

end;
define module dhcp
  use common-dylan;
  use packetizer;
  use ipv4, import: { <ipv4-address>, <udp-frame>, ipv4-address, operation };
  export <dhcp-message>,
    <dhcp-message-type-option>,
    <dhcp-requested-ip-address-option>,
    <dhcp-server-identifier-option>,
    <dhcp-subnet-mask>,
    <dhcp-router-option>,
    <dhcp-end-option>,
    subnet-mask,
    addresses,
    message-type,
    dhcp-options,
    your-ip-address,
    server-ip-address,
    selected-server;
end;

define module dns
  use common-dylan;
  use packetizer;
  use byte-vector, import: { copy-bytes };
  use simple-io;
  use ipv4, import: { <ipv4-address>, <udp-frame> };

  export <dns-frame>,
    identifier, identifier-setter,
    query-or-response, query-or-response-setter,
    opcode, opcode-setter,
    authoritative-answer, authoritative-answer-setter,
    truncation, truncation-setter,
    recursion-desired, recursion-desired-setter,
    recursion-available, recursion-available-setter,
    reserved, reserved-setter,
    response-code, response-code-setter,
    question-count, question-count-setter,
    answer-count, answer-count-setter,
    additional-count, additional-count-setter,
    questions, questions-setter,
    answers, answers-setter,
    name-servers, name-servers-setter,
    additional-records, additional-records-setter;

  export <domain-name>,
    fragment, fragment-setter;

  export <domain-name-fragment>,
    type-code, type-code-setter,
    <label-offset>, offset, offset-setter,
    <label>, data-length, data-length-setter, raw-data, raw-data-setter;

  export <dns-question>,
    domainname, domainname-setter,
    question-type, question-type-setter,
    question-class, question-class-setter;

  export <dns-resource-record>,
    domainname, domainname-setter,
    rr-type, rr-type-setter,
    rr-class, rr-class-setter,
    ttl, ttl-setter,
    rdlength, rdlength-setter,
    rdata, rdata-setter;

  export <a-host-address>,
    ipv4-address, ipv4-address-setter;

  export <name-server>,
    ns-name, ns-name-setter;

  export <canonical-name>,
    cname, cname-setter;

  export <start-of-authority>,
    nameserver, nameserver-setter,
    hostmaster, hostmaster-setter,
    serial, serial-setter,
    refresh, refresh-setter,
    retry, retry-setter,
    expire, expire-setter,
    minimum, minimum-setter;

  export <domain-name-pointer>,
    ptr-name, ptr-name-setter;

  export <character-string>,
    data-length, data-length-setter,
    string-data, string-data-setter;

  export <host-information>,
    cpu, cpu-setter,
    operating-system, operating-system-setter;

  export <mail-exchange>,
    preference, preference-setter,
    exchange, exchange-setter;

  export <text-strings>,
    text-data, text-data-setter;
end;

define module rip
  use dylan;
  use packetizer;
  use ipv4, import: { <udp-frame>, <ipv4-address> };

  export <rip-v1>, <rip-v2>,
    command, command-setter,
    version, version-setter,
    routes, routes-setter;

  export <rip-v1-route>, <rip-v2-route>,
    address-family-identifier, address-family-identifier-setter,
    route-ip-address, route-ip-address-setter,
    metric, metric-setter,
    route-tag, route-tag-setter,
    subnet-mask, subnet-mask-setter,
    next-hop, next-hop-setter;

  export <rip-v2-authentication>,
    authentication-id, authentication-id-setter,
    authentication-type, authentication-type-setter,
    authentication-value, authentication-value-setter;

  export <rip-ng>,
    <rip-ng-route>,
    ipv6-prefix, ipv6-prefix-setter,
    prefix-length, prefix-length-setter;
end;

define module cidr
  use dylan-extensions;
  use common-dylan, exclude: { format-to-string };
  use ipv4, import: { ipv4-address, <ipv4-address> };
  use print;
  use format;
  use format-out;
  use packetizer;
  use common-extensions, exclude: { format-to-string };

  export <cidr>,
    base-network-address,
    cidr-network-address, cidr-netmask,
    ip-in-cidr?, broadcast-address,
    netmask-from-byte-vector;
end;

define module hsrp
  use dylan;
  use packetizer;
  use format;

  use ipv4, import: { <ipv4-address>, <udp-frame> };
end;

define module ntp
  use dylan;
  use packetizer;
  use format;

  use ipv4, import: { ipv4-address, <ipv4-address>, <udp-frame> };
  use pcap, import: { <unix-time-value> };
end;
