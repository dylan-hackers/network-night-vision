module: ntp

// Simple Network Time Protocol (SNTP) RFC 1769
define protocol ntp (container-frame)
  summary "NTP v%= mode: %=", version, mode;
  over <udp-frame> 123;
  enum field leap-indicator :: <2bit-unsigned-integer> = 0,
    mappings: { 0 <=> #"nowarning",
                1 <=> #"longminute",
                2 <=> #"shortminute",
                3 <=> #"notsync" };
  field version :: <3bit-unsigned-integer> = 3;
  enum field mode :: <3bit-unsigned-integer> = 3,
    mappings: { 0 <=> #"reserved",
                1 <=> #"symmetric active",
                2 <=> #"symmetric passive",
                3 <=> #"client",
                4 <=> #"server",
                5 <=> #"broadcast",
                6 <=> #"control",
                7 <=> #"private" };
  /*
    0 unspecified or unavailable
    1 primary reference (e.g., radio clock)
    2-15 secondary reference (via NTP or SNTP)
    16-255 reserved
  */
  field stratum :: <unsigned-byte> = 2;
  field poll-interval :: <unsigned-byte> = 10;
  field precision :: <unsigned-byte> = 0;
  field root-delay :: <big-endian-unsigned-integer-4byte> = 0;
  field root-dispersion :: <big-endian-unsigned-integer-4byte> = 0;
  field reference-clock-id :: <ipv4-address>;
  field reference-timestamp :: <unix-time-value>
    = make-unix-time(current-date() - make(<date>, year: 1970, month: 1, day: 1));
  field originate-timestamp :: <unix-time-value>
    = make-unix-time(current-date() - make(<date>, year: 1970, month: 1, day: 1));
  field receive-timestamp :: <unix-time-value>
    = make-unix-time(current-date() - make(<date>, year: 1970, month: 1, day: 1));
  field transmit-timestamp :: <unix-time-value>
    = make-unix-time(current-date() - make(<date>, year: 1970, month: 1, day: 1));
/* Authenticator (optional)
  field key-id :: <big-endian-unsigned-integer-4byte>;
  field message-authentication-code :: 16 bytes
*/
end;
