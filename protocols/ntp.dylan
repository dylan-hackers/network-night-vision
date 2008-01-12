module: ntp

// Simple Network Time Protocol (SNTP) RFC 1769
define protocol ntp (container-frame)
  over <udp-frame> 123;
  field leap-indicator :: <2bit-unsigned-integer> = 0;
  /*
    0 nowarning
    1 longminute, last minute has 61 seconds
    2 shortminute, last minute has 59 seconds
    3 notsync, alarm condition (clock not synchronized)
  */
  field version :: <3bit-unsigned-integer> = 3;
  /*
    0 reserved
    1 symmetric active
    2 symmetric passive
    3 client
    4 server
    5 broadcast
    6 control
    7 private
  */
  field mode :: <3bit-unsigned-integer> = 3;
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
  field reference-timestamp :: <unix-time-value>;
  field originate-timestamp :: <unix-time-value>;
  field receive-timestamp :: <unix-time-value>;
  field transmit-timestamp :: <unix-time-value>;
/* Authenticator (optional)
  field key-id :: <big-endian-unsigned-integer-4byte>;
  field message-authentication-code :: 16 bytes
*/
end;

define method summary (frame :: <ntp>) => (res :: <string>)
  if(frame.mode = 1)
    format-to-string("NTP v%= Symmetric active", frame.version)
  elseif(frame.mode = 2)
    format-to-string("NTP v%= Symmetric passive", frame.version)
  elseif(frame.mode = 3)
    format-to-string("NTP v%= Client", frame.version)
  elseif(frame.mode = 4)
    format-to-string("NTP v%= Server", frame.version)
  else
    format-to-string("NTP v%= mode: %=",
                     frame.version,
                     frame.mode)
  end
end;
