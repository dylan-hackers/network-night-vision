module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define function hex(integer :: <integer>, #key size)
 => (string :: <string>)
  integer-to-string(integer, base: 16, size: size)
end function hex;

define method hexdump (stream :: <stream>, sequence :: <sequence>) => ()
  if(sequence.size > 16)
    format(stream, "\n");
  end;
  for (byte keyed-by index in sequence)
    if(sequence.size > 16 & modulo(index, 16) == 0)
      format(stream, "%s  ", hex(index, size: 4))
    end;
    format(stream, "%s", hex(byte, size: 2));
    if(modulo(index, 16) == 15 
         | (index == sequence.size - 1 & sequence.size > 16))
      format(stream, "\n")
    elseif(modulo(index, 16) == 7)
      format(stream, "  ");
    else
      format(stream, " ");
    end if;
  end for;
end method hexdump;

// This is not a fix.
define method as(type == <string>, object :: <integer>)
 => (res :: <string>)
  concatenate("0x", hex(object))
end;
/*
define method as(type == <string>, object :: <stretchy-vector>)
 => (res :: <string>)
  apply(concatenate, "", map(curry(as, <string>), object))
end;
*/
define inline function bit-offset (offset :: <integer>) => (res :: <integer>)
  logand(7, offset);
end;

define inline function byte-offset (offset :: <integer>) => (res :: <integer>)
  ash(offset, -3);
end;

define inline function byte-aligned (offset :: <integer>)
  alignment-assert(bit-offset(offset) = 0);
end;

define inline function alignment-assert (func)
 unless (func)
   signal(make(<alignment-error>))
 end;
end;

define method byte-vector-to-bit-vector-lsb-first (bytes :: <byte-vector>)
  => (bits :: <bit-vector>)
  let result = make(<bit-vector>, size: bytes.size * 8);
  for (byte in bytes, byte-count from 0)
    for (bit from 0 below 8)
      result[bit + 8 * byte-count] := ash(logand(byte, ash(1, bit)), - bit);
    end;
  end;
  result;
end;

define method byte-vector-to-bit-vector-msb-first (bytes :: <byte-vector>)
  => (bits :: <bit-vector>)
  let result = make(<bit-vector>, size: bytes.size * 8);
  for (byte in bytes, byte-count from 0)
    for (bit from 7 to 0 by -1)
      result[7 - bit + 8 * byte-count] := ash(logand(byte, ash(1, bit)), - bit);
    end;
  end;
  result;
end;

define method bit-vector-to-byte-vector-lsb-first (bits :: <bit-vector>)
 => (bytes :: <byte-vector>)
 let result = make(<byte-vector>, size: ash(bits.size + 7, - 3), fill: 0);
 for (byte from 0 below result.size)
   for (bit from 7 to 0 by -1)
     result[byte] := ash(result[byte], 1) + element(bits, byte * 8 + bit, default: 0);
   end;
 end;
 result;
end;

define method bit-vector-to-byte-vector-msb-first (bits :: <bit-vector>)
 => (bytes :: <byte-vector>)
 let result = make(<byte-vector>, size: ash(bits.size + 7, - 3), fill: 0);
 for (byte from 0 below result.size)
   for (bit from 0 below 8)
     result[byte] := ash(result[byte], 1) + element(bits, byte * 8 + bit, default: 0);
   end;
 end;
 result;
end;


