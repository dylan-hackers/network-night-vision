module:         id3v2
Author:         Andreas Bogk, Hannes Mehnert, mb
Copyright:      (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define class <4byte-7bit-big-endian-unsigned-integer> (<fixed-size-translated-leaf-frame>)
end;

define inline method high-level-type
    (low-level-type == <4byte-7bit-big-endian-unsigned-integer>)
 => (res :: <type>)
  limited(<integer>, min: 0, max: 2 ^ 28);
end;

define inline method field-size (field == <4byte-7bit-big-endian-unsigned-integer>)
 => (length :: <integer>)
  4 * 8;
end;

define method parse-frame
    (frame-type == <4byte-7bit-big-endian-unsigned-integer>, packet :: <byte-sequence>,
     #key start :: <integer> = 0)
 => (value :: <integer>, next-unparsed :: <integer>)
  byte-aligned(start);
  let byte-start = byte-offset(start);
  if (packet.size < byte-start + 4)
    signal(make(<malformed-packet-error>))
  else
    let result = 0;
    for (i from byte-start below byte-start + 4)
      result := packet[i] + ash(result, 7)
    end;
    values(result, start + 8 * 4);
  end;
end;

define protocol id3v2-string (container-frame)
end;

define protocol id3v2-string-with-type (id3v2-string)
  field string-type :: <unsigned-byte>;
end;

define protocol ascii-string-with-type (id3v2-string-with-type)
  field string-data :: <externally-delimited-string>;
end;

define protocol ascii-string (id3v2-string)
  field string-data :: <externally-delimited-string>;
end;

define method parse-frame
    (frame-type == <id3v2-string>, packet :: <byte-sequence>, #key start :: <integer> = 0)
 => (value :: <id3v2-string>, next-unparsed :: false-or(<integer>))
  let type-code = if (packet.size == 0) #x10 else packet[0] end if;
  let string-type = select (type-code)
                      #x00 => <ascii-string-with-type>;
                        otherwise <ascii-string>;
                    end select;
  parse-frame(string-type, packet, start: start);
end;

define protocol id3v2-flags (container-frame)
  field unsynchronisation :: <1bit-unsigned-integer>;
  field extended-header :: <1bit-unsigned-integer>;
  field experimental-indicator :: <1bit-unsigned-integer>;
  field footer-present :: <1bit-unsigned-integer>;
  field dummy :: <4bit-unsigned-integer>;	// must be zero
end;

define protocol id3v2-frame (container-frame)
  field frame-id :: <externally-delimited-string>, static-length: 8 * 4;
  field id3v2-frame-size :: <4byte-7bit-big-endian-unsigned-integer>,
    fixup: byte-offset(frame-size(frame.id3v2-data));
  field flags :: <2byte-big-endian-unsigned-integer>;
  field id3v2-data :: <id3v2-string>, length: frame.id3v2-frame-size * 8;
  /* field string-type :: <unsigned-byte>;
  field id3v2-data :: <externally-delimited-string>,
    length: if (frame.id3v2-frame-size > 0)
                (frame.id3v2-frame-size - 1) * 8;
            else 
                0;
            end if; */
end;

define protocol id3v2-header (container-frame)
  field identifier :: <externally-delimited-string>,
    static-length: 8 * 3;
  field major-version :: <unsigned-byte>;
  field revision :: <unsigned-byte>;
  field flags :: <id3v2-flags>;
  field tag-size :: <4byte-7bit-big-endian-unsigned-integer>;
end;

define protocol id3v2-tag (header-frame)
  field id3v2-header :: <id3v2-header>;
  repeated field id3v2-frame :: <id3v2-frame>,
    reached-end?: 
      method (frame :: <id3v2-frame>)
        if (frame.frame-id.data[0] == #x00)
          #t;
        else 
          #f;
        end if;
      end method;
  //field payload :: <raw-frame>, start: frame.id3v2-header.tag-size * 8;
end;
