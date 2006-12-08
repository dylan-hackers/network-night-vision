module: openpgp

define protocol string-to-key (variably-typed-container-frame)
  layering field type :: <unsigned-byte>;
  field hash-algorithm :: <unsigned-byte> = 0;
end;

define protocol simple-string-to-key (string-to-key)
  over <string-to-key> 0;
end;

define protocol salted-string-to-key (string-to-key)
  over <string-to-key> 1;
  field salt-value :: <raw-frame>, static-length: 8 * 8;
end;

define protocol iterated-and-salted-string-to-key (string-to-key)
  over <string-to-key> 3;
  field salt-value :: <raw-frame>, static-length: 8 * 8;
  field salt-count :: <unsigned-byte> = 0;
end;


//#define EXPBIAS 6
// count = ((Int32)16 + (c & 15)) << ((c >> 4) + EXPBIAS);
//32bit-ints, c = count

define protocol openpgp-packet-header (variably-typed-container-frame)
  field always-one :: <1bit-unsigned-integer> = 1;
  layering field new-packet-format :: <1bit-unsigned-integer>;
end;

define protocol old-openpgp-packet (opengpg-packet-header)
  over <openpgp-packet-header> 0;
  field content-tag :: <4bit-unsigned-integer> = 0;
  field length-type :: <2bit-unsigned-integer>;
end;
/*
 0 - The packet has a one-octet length. The header is 2 octets long.
 1 - The packet has a two-octet length. The header is 3 octets long.
 2 - The packet has a four-octet length. The header is 5 octets long.
 3 - The packet is of indeterminate length.  The header is 1 octet
       long, and the implementation must determine how long the packet
       is. If the packet is in a file, this means that the packet
       extends until the end of the file. In general, an implementation
       SHOULD NOT use indeterminate length packets except where the end
       of the data will be clear from the context, and even then it is
       better to use a definite length, or a new-format header. The
       new-format headers described below have a mechanism for precisely
       encoding data of indeterminate length.
*/


define protocol new-openpgp-packet (openpgp-packet-header)
  over <openpgp-packet-header> 1;
  field content-tag :: <6bit-unsigned-integer>;
end;


define protocol public-key-encrypted-session-key-packet (container-frame)
  field version-number :: <unsigned-byte> = 3;
  field public-key-id :: <raw-frame>, static-length: 8 * 8;
  field public-key-algorithm :: <unsigned-byte>;
  field encrypted-session-key :: <raw-frame>;
end;

//define protocol signature-packet (container-frame)
  