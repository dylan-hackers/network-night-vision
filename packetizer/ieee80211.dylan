module:         packetizer
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

define n-byte-vector(wlan-device-name, 16) end;
define n-byte-vector(timestamp, 8) end;
define n-bit-unsigned-integer(<11bit-unsigned-integer>; 11) end;
define n-bit-unsigned-integer(<12bit-unsigned-integer>; 12) end;

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
define protocol ieee80211-information-field (container-frame)
  field length :: <unsigned-byte>,
    fixup: byte-offset(frame-size(frame.data));
end;

define protocol ieee80211-raw-information-field (ieee80211-information-field)
  field data :: <raw-frame>,
    length: frame.length * 8;
end;

define protocol ieee80211-ssid (ieee80211-information-field)
  summary "SSID: %=", data;
  field data :: <externally-delimited-string>,
    length: frame.length * 8;
end;

define protocol ieee80211-fh-set (ieee80211-raw-information-field)
end;

define protocol ieee80211-ds-set (ieee80211-raw-information-field)
end;

define protocol ieee80211-cf-set (ieee80211-raw-information-field)
end;

define protocol ieee80211-tim (ieee80211-raw-information-field)
end;

define protocol ieee80211-ibss (ieee80211-raw-information-field)
end;

define protocol ieee80211-challenge-text (ieee80211-raw-information-field)
end;

define protocol ieee80211-supported-rates (ieee80211-information-field)
  repeated field supported-rate :: <rate>,
    reached-end?: method(x) #f end,
    length: frame.length * 8;
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
                #x30 => "24";
                #x48 => "36";
                #x60 => "48";
                #x6c => "54";
                otherwise => "Unknown";
              end,
              " Mbit");
end;

define method parse-frame (frame == <rate>, packet :: <byte-sequence>, #key start = 0)
  let f = make(unparsed-class(frame), packet: packet);
  let type = select (f.bss-basic-set?)
               0 => <extended-rate>;
               1 => <basic-set-rate>;
             end;
  parse-frame(type, packet, start: start);
end;

define protocol ieee80211-reserved-field (ieee80211-raw-information-field)
end;

// ieee80211 information elements (information field header)
define protocol ieee80211-information-element (container-frame)
  summary "%s", compose(summary, information-field);
  field element-id :: <unsigned-byte>;
  variably-typed-field information-field, 
    type-function:
      select (frame.element-id)
        $information-element-ssid => <ieee80211-ssid>;
        $information-element-supported-rates => <ieee80211-supported-rates>;
        $information-element-fh-set => <ieee80211-fh-set>;
        $information-element-cf-set => <ieee80211-cf-set>;
        $information-element-ds-set => <ieee80211-ds-set>;
        $information-element-tim => <ieee80211-tim>;
        $information-element-ibss => <ieee80211-ibss>;
        $information-element-challenge-text => <ieee80211-challenge-text>;
          // TODO: need more info about various (commercially-used) fields
          otherwise <ieee80211-reserved-field>;
      end select;
end;

// management frames
define protocol ieee80211-management-frame (container-frame)
  summary "DST %=, SRC %=, BSSID %=", destination-address,
    source-address, bssid;
  field duration :: <2byte-little-endian-unsigned-integer>;
  field destination-address :: <mac-address>;
  field source-address :: <mac-address>;
  field bssid :: <mac-address>;
  field sequence-control  :: <ieee80211-sequence-control>;
end;

define protocol ieee80211-disassociation (ieee80211-management-frame)
  summary "DISASSOC %=", method (x) next-method() end;
  field reason-code :: <2byte-little-endian-unsigned-integer>;
end;

define protocol ieee80211-association-request (ieee80211-management-frame)
  summary "ASSOC-REQ %= %s", method (x) next-method() end, compose(summary, ssid);
  field capability-information :: <ieee80211-capability-information>;
  field listen-interval :: <2byte-little-endian-unsigned-integer>;
  field ssid :: <ieee80211-information-element>;
  field supported-rates :: <ieee80211-information-element>;
end;

define protocol ieee80211-association-response (ieee80211-management-frame)
  field capability-information :: <ieee80211-capability-information>;
  field status-code :: <2byte-little-endian-unsigned-integer>;
  field association-id :: <2byte-little-endian-unsigned-integer>;
  field supported-rates :: <ieee80211-information-element>;
end;

define protocol ieee80211-reassociation-request (ieee80211-management-frame)
  summary "REASSOC %s", compose(summary, ssid);
  field capabilty-information :: <ieee80211-capability-information>;
  field listen-intervall :: <2byte-little-endian-unsigned-integer>;
  field current-ap-address :: <mac-address>;
  field ssid :: <ieee80211-information-element>;
  field supported-rates :: <ieee80211-information-element>;
end;

define protocol ieee80211-reassociation-response (ieee80211-management-frame)
  field capability-information :: <ieee80211-capability-information>;
  field status-code :: <2byte-little-endian-unsigned-integer>;
  field association-id :: <2byte-little-endian-unsigned-integer>;
  field supported-rates :: <ieee80211-information-element>;
end;

define protocol ieee80211-probe-request (ieee80211-management-frame)
  summary "PROBE-REQ %= %s", method(x) next-method() end, compose(summary, ssid);
  field ssid :: <ieee80211-information-element>;
  field supported-rates :: <ieee80211-information-element>;
end;

define protocol ieee80211-probe-response (ieee80211-management-frame)
  summary "PROBE-RESP %= %s", method (x) next-method() end, compose(summary, ssid);
  field timestamp :: <timestamp>;
  field beacon-intervall :: <2byte-little-endian-unsigned-integer>;
  field capability-information :: <ieee80211-capability-information>;
  field ssid :: <ieee80211-information-element>;
  field supported-rates :: <ieee80211-information-element>;
  repeated field additional-information :: <ieee80211-information-element>,
    reached-end?: method (x) #f end;
end;

define protocol ieee80211-authentication (ieee80211-management-frame)
  summary "AUTH %=", method (x) next-method() end;
  field algorithm-number :: <2byte-little-endian-unsigned-integer>;
  field transaction-sequence-number :: <2byte-little-endian-unsigned-integer>;
  field status-code :: <2byte-little-endian-unsigned-integer>;
  repeated field additional-information :: <ieee80211-information-element>,
    reached-end?: method (x) #f end;
end;

define protocol ieee80211-deauthentication (ieee80211-management-frame)
  field reason-code :: <2byte-little-endian-unsigned-integer>;
end;

define protocol ieee80211-atim (ieee80211-management-frame)
end;

define protocol ieee80211-beacon (ieee80211-management-frame)
  summary "BEACON %= %s", method (x) next-method() end, compose(summary, ssid);
  field timestamp :: <timestamp>;
  field beacon-interval :: <2byte-little-endian-unsigned-integer>;
  field capability-information :: <2byte-little-endian-unsigned-integer>;
  field ssid :: <ieee80211-information-element>;
  field supported-rates :: <ieee80211-information-element>;
  repeated field additional-information :: <ieee80211-information-element>,
    reached-end?: method (x) #f end;
end;

// ieee80211 data frames
define protocol ieee80211-data-frame (header-frame)
  field duration-id :: <2byte-little-endian-unsigned-integer>;
  field mac-address-one :: <mac-address>;
  field mac-address-two :: <mac-address>;
  field mac-address-three :: <mac-address>;
  field sequence-control ::  <ieee80211-sequence-control>;
end;

define protocol ieee80211-null-function (ieee80211-data-frame)
  summary "NULL-FUNCTION %=", method (x) next-method() end;
  field payload :: <raw-frame>; // there should be no data
end;

define protocol ieee80211-data (ieee80211-data-frame)
  summary "%s", compose(summary, payload);
  field payload :: <link-control>;
end;

// ieee80211 control frames
define protocol ieee80211-control-frame(container-frame)
end;

define protocol ieee80211-request-to-send (ieee80211-control-frame)
  field duration :: <2byte-little-endian-unsigned-integer>;
  field receiver-address :: <mac-address>;
  field transmitter-address :: <mac-address>;
end;

define protocol ieee80211-cts-and-ack (ieee80211-control-frame)
  field duration :: <2byte-little-endian-unsigned-integer>;
  field receiver-address :: <mac-address>;
end;

define protocol ieee80211-ps-poll (ieee80211-control-frame)
  field association-id :: <2byte-little-endian-unsigned-integer>;
  field bssid :: <mac-address>;
  field transmitter-address :: <mac-address>;
end;

define protocol ieee80211-cf-end (ieee80211-control-frame)
  field duration :: <2byte-little-endian-unsigned-integer>;
  field receiver-address :: <mac-address>;
  field bssid :: <mac-address>;
end;

// frame control field of each <ieee80211-frame>
define protocol ieee80211-frame-control (container-frame)
  summary "WEP: %=", wep;
  field subtype :: <4bit-unsigned-integer>;
  field type :: <2bit-unsigned-integer>;
  field protcol-version :: <2bit-unsigned-integer>;
  field order :: <1bit-unsigned-integer>;
  field wep :: <1bit-unsigned-integer>;
  field more-data :: <1bit-unsigned-integer>;
  field power-management :: <1bit-unsigned-integer>;
  field retry :: <1bit-unsigned-integer>;
  field more-fragments :: <1bit-unsigned-integer>;
  field to-ds :: <1bit-unsigned-integer>;
  field from-ds :: <1bit-unsigned-integer>;
end;

define protocol ieee80211-frame (header-frame)
  summary "IEEE80211 %s/%s", compose(summary, frame-control), compose(summary, payload);
  field frame-control :: <ieee80211-frame-control>;
  variably-typed-field payload,
    type-function: 
      select (frame.frame-control.type)
        $management-frame =>
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
        $control-frame =>
          select (frame.frame-control.subtype)
            $power-save-poll => <ieee80211-ps-poll>;
            $request-to-send => <ieee80211-request-to-send>;
            // XXX: split up
            $clear-to-send, $acknowledgement => <ieee80211-cts-and-ack>;
            $contention-free-end, $cf-end-cf-ack => <ieee80211-cf-end>;
              otherwise signal(make(<malformed-packet-error>));
          end select;
        $data-frame =>
          select (frame.frame-control.subtype)
            // XXX: split up (inheritance)
            $data, $data-cf-ack, $data-cf-poll, $data-cf-ack-cf-poll
              => <ieee80211-data>;
            $data-null-function, $cf-poll-no-data, $cf-ack-no-data, $cf-ack-cf-poll-no-data
              => <ieee80211-null-function>;
              otherwise signal(make(<malformed-packet-error>));
          end select;
          otherwise signal(make(<malformed-packet-error>));
      end select;
end;

