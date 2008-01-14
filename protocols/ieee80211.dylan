module:         ieee80211
Author:         Andreas Bogk, Hannes Mehnert, mb
Copyright:      (C) 2005, 2006,  All rights reserved. Free for non-commercial use.


// main frame types
define constant $management-frame = #x0;
define constant $control-frame = #x1;
define constant $data-frame = #x2;

// management frame subtypes
define constant $association-request = #b0000;
define constant $association-response = #b0001;
define constant $reassociation-request = #b0010;
define constant $reassociation-response = #b0011;
define constant $probe-request = #b0100;
define constant $probe-response = #b0101;
define constant $beacon = #b1000;
define constant $atim = #b1001;
define constant $disassociation = #b1010;
define constant $authentication = #b1011;
define constant $deauthentication = #b1100;

// data frame subtypes
define constant $data = #b0000;
define constant $data-cf-ack = #b0001;
define constant $data-cf-poll = #b0010;
define constant $data-cf-ack-cf-poll = #b0011;
define constant $data-null-function = #b0100;
define constant $cf-ack-no-data = #b0101;
define constant $cf-poll-no-data = #b0110;
define constant $cf-ack-cf-poll-no-data = #b0111;
define constant $qos-data = #b1000;
define constant $qos-data-cf-ack = #b1001;
define constant $qos-data-cf-poll = #b1010;
define constant $qos-data-cf-ack-cf-poll = #b1011;
define constant $qos-null-function = #b1100;
define constant $qos-cf-poll-no-data = #b1110;
define constant $qos-cf-ack-cf-poll-no-data = #b1111;

// control frame subtypes
define constant $power-save-poll = #b1010;
define constant $request-to-send = #b1011;
define constant $clear-to-send = #b1100;
define constant $acknowledgement = #b1101;
define constant $contention-free-end = #b1110;
define constant $cf-end-cf-ack = #b1111;

// information field id's
define constant $information-element-ssid = 0;
define constant $information-element-supported-rates = 1;
define constant $information-element-fh-set = 2;
define constant $information-element-ds-set = 3;
define constant $information-element-cf-set = 4;
define constant $information-element-tim = 5;
define constant $information-element-ibss = 6;
define constant $information-element-challenge-text = 16;

define n-byte-vector(timestamp, 8) end;

define protocol ieee80211-sequence-control (container-frame)
  field sequence-number :: <12bit-unsigned-integer>;
  field fragment-number :: <4bit-unsigned-integer>;
end;

define protocol ieee80211-capability-information (container-frame)
  field reserved :: <11bit-unsigned-integer>;
  field privacy :: <1bit-unsigned-integer>;
  field cf-poll-request :: <1bit-unsigned-integer>;
  field cf-pollabel :: <1bit-unsigned-integer>;
  field ibss :: <1bit-unsigned-integer>;
  field ess :: <1bit-unsigned-integer>;
end;

// ieee80211 information fields
// TODO: need more info about various (commercially-used) fields
define protocol ieee80211-information-element (variably-typed-container-frame)
  length (2 + frame.data-length) * 8;
  layering field element-id :: <unsigned-byte>;
  field data-length :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame)) - 2;
end;

define method parse-frame (frame == <ieee80211-information-element>,
                           packet :: <byte-sequence>,
                           #next next-method,
                           #key parent)
  block()
    next-method(frame, packet, parent: parent, default: #f);
  exception (e :: <error>)
    parse-frame(<ieee80211-reserved-field>, packet, parent: parent);
  end;
end;

define protocol ieee80211-raw-information-element (ieee80211-information-element)
  field raw-data :: <raw-frame>;
end;

define protocol ieee80211-reserved-field (ieee80211-raw-information-element)
end;

define protocol ieee80211-ssid (ieee80211-information-element)
  over <ieee80211-information-element> $information-element-ssid;
  summary "SSID: %=", raw-data;
  field raw-data :: <externally-delimited-string>;
end;

define protocol ieee80211-fh-set (ieee80211-raw-information-element)
  over <ieee80211-information-element> $information-element-fh-set;
end;

define protocol ieee80211-ds-set (ieee80211-raw-information-element)
  over <ieee80211-information-element> $information-element-ds-set;
end;

define protocol ieee80211-cf-set (ieee80211-raw-information-element)
  over <ieee80211-information-element> $information-element-cf-set;
end;

define protocol ieee80211-tim (ieee80211-raw-information-element)
  over <ieee80211-information-element> $information-element-tim;
end;

define protocol ieee80211-ibss (ieee80211-raw-information-element)
  over <ieee80211-information-element> $information-element-ibss;
end;

define protocol ieee80211-challenge-text (ieee80211-raw-information-element)
  over <ieee80211-information-element> $information-element-challenge-text;
end;

define protocol ieee80211-supported-rates (ieee80211-information-element)
  over <ieee80211-information-element> $information-element-supported-rates;
  repeated field supported-rate :: <rate>,
    reached-end?: #f;
end;

define method summary (frame :: <rate>) => (res :: <string>)
  as(<string>, frame);
end;

define protocol rate (container-frame)
  field bss-basic-set? :: <1bit-unsigned-integer>;
  field real-rate :: <7bit-unsigned-integer>;
end;

define protocol basic-set-rate (rate)
end;

define method as (class == <string>, frame :: <basic-set-rate>) => (res :: <string>)
  concatenate("CCK ",
              select (frame.real-rate)
                2 => "1";
                4 => "2";
                #xb => "5";
                #x16 => "11";
                otherwise => "Unknown rate";
              end,
              " Mbit");
end;

define protocol extended-rate (rate)
end;

define method as (class == <string>, frame :: <extended-rate>) => (res :: <string>)
  concatenate("OFDM ",
              select (frame.real-rate)
                #xc => "6";
                #x12 => "9";
                #x18 => "12";
                #x24 => "18";
                #x2c => "22"; //stolen from wireshark
                #x30 => "24";
                #x48 => "36";
                #x60 => "48";
                #x6c => "54";
                otherwise => "Unknown";
              end,
              " Mbit");
end;

define method parse-frame (frame == <rate>,
                           packet :: <byte-sequence>,
                           #next next-method,
                           #key parent)
  let f = next-method();
  let type = select (f.bss-basic-set?)
               0 => <extended-rate>;
               1 => <basic-set-rate>;
             end;
  parse-frame(type, packet, parent: parent);
end;

//frame control
define protocol ieee80211-frame-control (variably-typed-container-frame)
  field subtype :: <4bit-unsigned-integer>;
  layering field ftype :: <2bit-unsigned-integer>;
  field protocol-version :: <2bit-unsigned-integer>;
  field order :: <1bit-unsigned-integer>;
  field wep :: <1bit-unsigned-integer>;
  field more-data :: <1bit-unsigned-integer>;
  field power-management :: <1bit-unsigned-integer>;
  field retry :: <1bit-unsigned-integer>;
  field more-fragments :: <1bit-unsigned-integer>;
  field to-ds :: <1bit-unsigned-integer>;
  field from-ds :: <1bit-unsigned-integer>;
end;

// ieee80211 frame
define abstract protocol ieee80211-frame (header-frame)
  field frame-control :: <ieee80211-frame-control>;
end;

define method parse-frame (frame == <ieee80211-frame>,
                           packet :: <byte-sequence>,
                           #next next-method,
                           #key parent)
  let f = next-method();
  let type = select (f.frame-control.ftype)
               $management-frame => <ieee80211-management-frame>;
               $data-frame => <ieee80211-data-frame>;
               $control-frame => <ieee80211-control-frame>;
               otherwise => signal(make(<malformed-packet-error>));
             end;
  parse-frame(type, packet, parent: parent);
end;

// ieee80211 management frames
define protocol ieee80211-management-frame (ieee80211-frame)
  summary "DST %=, SRC %=, BSSID %=", destination-address, source-address, bssid;
  field duration :: <2byte-little-endian-unsigned-integer>;
  field destination-address :: <mac-address>;
  field source-address :: <mac-address>;
  field bssid :: <mac-address>;
  field sequence-control  :: <ieee80211-sequence-control>;
  variably-typed-field payload,
    type-function:
      select (frame.frame-control.subtype)
        $atim => <ieee80211-atim>;
        $beacon => <ieee80211-beacon>;
        $disassociation => <ieee80211-disassociation>;
        $association-request => <ieee80211-association-request>;
        $association-response => <ieee80211-association-response>;
        $reassociation-request => <ieee80211-reassociation-request>;
        $reassociation-response => <ieee80211-reassociation-response>;
        $probe-request => <ieee80211-probe-request>;
        $probe-response => <ieee80211-probe-response>;
        $authentication => <ieee80211-authentication>;
        $deauthentication => <ieee80211-deauthentication>;
          otherwise signal(make(<malformed-packet-error>));
      end select;
end;

define protocol ieee80211-disassociation (container-frame)
  summary "DISASSOC";
  field reason-code :: <2byte-little-endian-unsigned-integer>;
end;

define protocol ieee80211-association-request (container-frame)
  summary "ASSOC-REQ %s", compose(summary, ssid);
  field capability-information :: <ieee80211-capability-information>;
  field listen-interval :: <2byte-little-endian-unsigned-integer>;
  field ssid :: <ieee80211-information-element>;
  field supported-rates :: <ieee80211-information-element>;
end;

define protocol ieee80211-association-response (container-frame)
  field capability-information :: <ieee80211-capability-information>;
  field status-code :: <2byte-little-endian-unsigned-integer>;
  field association-id :: <2byte-little-endian-unsigned-integer>;
  field supported-rates :: <ieee80211-information-element>;
end;

define protocol ieee80211-reassociation-request (container-frame)
  summary "REASSOC";
  field capabilty-information :: <ieee80211-capability-information>;
  field listen-intervall :: <2byte-little-endian-unsigned-integer>;
  field current-ap-address :: <mac-address>;
  field ssid :: <ieee80211-information-element>;
  field supported-rates :: <ieee80211-information-element>;
end;

define protocol ieee80211-reassociation-response (container-frame)
  field capability-information :: <ieee80211-capability-information>;
  field status-code :: <2byte-little-endian-unsigned-integer>;
  field association-id :: <2byte-little-endian-unsigned-integer>;
  field supported-rates :: <ieee80211-information-element>;
end;

define protocol ieee80211-probe-request (container-frame)
  summary "PROBE-REQ %s", compose(summary, ssid);
  field ssid :: <ieee80211-information-element>;
  field supported-rates :: <ieee80211-information-element>;
end;

define protocol ieee80211-probe-response (container-frame)
  summary "PROBE-RESP %s", compose(summary, ssid);
  field timestamp :: <timestamp>;
  field beacon-intervall :: <2byte-little-endian-unsigned-integer>;
  field capability-information :: <ieee80211-capability-information>;
  field ssid :: <ieee80211-information-element>;
  field supported-rates :: <ieee80211-information-element>;
  repeated field additional-information :: <ieee80211-information-element>,
    reached-end?: #f;
end;

define protocol ieee80211-authentication (container-frame)
  summary "AUTH";
  field algorithm-number :: <2byte-little-endian-unsigned-integer>;
  field transaction-sequence-number :: <2byte-little-endian-unsigned-integer>;
  field status-code :: <2byte-little-endian-unsigned-integer>;
  repeated field additional-information :: <ieee80211-information-element>,
    reached-end?: #f;
end;

define protocol ieee80211-deauthentication (container-frame)
  field reason-code :: <2byte-little-endian-unsigned-integer>;
end;

define protocol ieee80211-atim (container-frame)
end;

define protocol ieee80211-beacon (container-frame)
  summary "BEACON %s", compose(summary, ssid);
  field timestamp :: <timestamp>;
  field beacon-interval :: <2byte-little-endian-unsigned-integer>;
  field capability-information :: <2byte-little-endian-unsigned-integer>;
  field ssid :: <ieee80211-information-element>;
  field supported-rates :: <ieee80211-information-element>;
  repeated field additional-information :: <ieee80211-information-element>,
    reached-end?: #f;
end;

// ieee80211 data frames
define protocol ieee80211-data-frame (ieee80211-frame)
  field duration-id :: <2byte-little-endian-unsigned-integer>;
  field mac-address-one :: <mac-address>;
  field mac-address-two :: <mac-address>;
  field mac-address-three :: <mac-address>;
  field sequence-control ::  <ieee80211-sequence-control>;
  variably-typed-field payload,
    type-function:
      select (frame.frame-control.subtype)
        // XXX: split up (inheritance)
        $data, $data-cf-ack, $data-cf-poll, $data-cf-ack-cf-poll
          => <link-control>;
        $data-null-function, $cf-poll-no-data, $cf-ack-no-data, $cf-ack-cf-poll-no-data
          => <ieee80211-null-function>;
        $qos-data, $qos-data-cf-ack, $qos-data-cf-poll, $qos-data-cf-ack-cf-poll,
        $qos-null-function, $qos-cf-poll-no-data, $qos-cf-ack-cf-poll-no-data
          => <ieee80211-qos-control>;
          otherwise signal(make(<malformed-packet-error>));
      end select;
end;

define protocol ieee80211-null-function (container-frame)
  summary "NULL-FUNCTION";
  field no-data :: <raw-frame> = $empty-raw-frame; // there should be no data
end;

define protocol ieee80211-qos-control (header-frame)
  summary "QOS-CONTROL";
  field traffic-identifier  :: <4bit-unsigned-integer>;
  field end-of-service-period :: <1bit-unsigned-integer>;
  field ack-policy :: <2bit-unsigned-integer>;
  field reserved :: <1bit-unsigned-integer>;
  field transmit-opportunity :: <unsigned-byte>;
  variably-typed-field payload,
    type-function:
      select (frame.parent.frame-control.subtype)
        $qos-null-function, $qos-cf-poll-no-data, $qos-cf-ack-cf-poll-no-data
          => <ieee80211-null-function>;
        $qos-data, $qos-data-cf-ack, $qos-data-cf-poll, $qos-data-cf-ack-cf-poll
          => <link-control>;
          otherwise signal(make(<malformed-packet-error>));
      end select;
end;

/*
define protocol ieee80211-data (header-frame)
  summary "%s", compose(summary, payload);
  field payload :: <link-control>;
end;
*/

// ieee80211 control frames
define protocol ieee80211-control-frame (ieee80211-frame)
  variably-typed-field payload,
    type-function:
      select (frame.frame-control.subtype)
        $power-save-poll => <ieee80211-ps-poll>;
        $request-to-send => <ieee80211-request-to-send>;
        // XXX: split up
        $clear-to-send, $acknowledgement => <ieee80211-cts-and-ack>;
        $contention-free-end, $cf-end-cf-ack => <ieee80211-cf-end>;
          otherwise signal(make(<malformed-packet-error>));
      end select;
end;

define protocol ieee80211-request-to-send (container-frame)
  field duration :: <2byte-little-endian-unsigned-integer>;
  field receiver-address :: <mac-address>;
  field transmitter-address :: <mac-address>;
end;

define protocol ieee80211-cts-and-ack (container-frame)
  field duration :: <2byte-little-endian-unsigned-integer>;
  field receiver-address :: <mac-address>;
end;

define protocol ieee80211-ps-poll (container-frame)
  field association-id :: <2byte-little-endian-unsigned-integer>;
  field bssid :: <mac-address>;
  field transmitter-address :: <mac-address>;
end;

define protocol ieee80211-cf-end (container-frame)
  field duration :: <2byte-little-endian-unsigned-integer>;
  field receiver-address :: <mac-address>;
  field bssid :: <mac-address>;
end;


