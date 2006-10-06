module: packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define abstract class <leaf-frame> (<frame>)
end;

define method print-object (object :: <leaf-frame>, stream :: <stream>) => ()
  write(stream, as(<string>, object));
end;

define abstract class <fixed-size-untranslated-leaf-frame>
    (<leaf-frame>, <fixed-size-untranslated-frame>)
end;

define abstract class <variable-size-untranslated-leaf-frame>
    (<leaf-frame>, <variable-size-untranslated-frame>)
end;

define open abstract class <fixed-size-translated-leaf-frame>
    (<leaf-frame>, <fixed-size-frame>, <translated-frame>)
end;

define abstract class <variable-size-translated-leaf-frame>
    (<leaf-frame>, <variable-size-frame>, <translated-frame>)
end;

define generic read-frame
  (frame-type :: subclass(<leaf-frame>), string :: <string>) => (frame);

define method read-frame (frame-type :: subclass(<leaf-frame>), string :: <string>)
 => (frame)
  error("read-frame not supported for frame-type %=", frame-type);
end;


define class <unsigned-byte> (<fixed-size-translated-leaf-frame>)
  slot data :: <byte>, init-keyword: data:;
end;

define method parse-frame (frame-type == <unsigned-byte>,
                           packet :: <byte-sequence>,
                           #key start :: <integer> = 0)
 => (value :: <byte>, next-unparsed :: <integer>)
  byte-aligned(start);
  if (packet.size < byte-offset(start) + 1)
    signal(make(<malformed-packet-error>))
  else
    values(packet[byte-offset(start)], start + 8)
  end;
end;

define method assemble-frame-into-as
    (frame-type == <unsigned-byte>,
     data :: <byte>,
     packet :: <stretchy-byte-vector-subsequence>) => (end-offset :: <integer>)
  packet[0] := data;
  8;
end;

define method as (class == <string>, frame :: <unsigned-byte>)
 => (string :: <string>)
  concatenate("0x", integer-to-string(frame.data, base: 16, size: 2));
end;

define inline method field-size (type == <unsigned-byte>)
  => (length :: <integer>)
  8
end;

define method read-frame (type == <unsigned-byte>,
                          string :: <string>)
 => (res)
  let res = string-to-integer(string);
  if (res < 0 | res > 2 ^ (field-size(type) - 1))
    signal(make(<out-of-range-error>))
  end;
  res;
end;
define inline method high-level-type (low-level-type == <unsigned-byte>)
 => (res == <byte>)
  <byte>;
end;


define abstract class <unsigned-integer-bit-frame> (<fixed-size-translated-leaf-frame>)
end;

define macro n-bit-unsigned-integer-definer
    { define n-bit-unsigned-integer(?:name; ?n:*) end }
     => { define class ?name (<unsigned-integer-bit-frame>)
            slot data :: limited(<integer>, min: 0, max: 2 ^ ?n - 1),
              required-init-keyword: data:;
          end;
          
          define inline method high-level-type (low-level-type == ?name)
            => (res :: <type>)
            limited(<integer>, min: 0, max: 2 ^ ?n - 1);
          end;

          define inline method field-size (type == ?name)
           => (length :: <integer>)
           ?n
          end; }
end;

define n-bit-unsigned-integer(<1bit-unsigned-integer>; 1) end;
define n-bit-unsigned-integer(<2bit-unsigned-integer>; 2) end;
define n-bit-unsigned-integer(<3bit-unsigned-integer>; 3) end;
define n-bit-unsigned-integer(<4bit-unsigned-integer>; 4) end;
define n-bit-unsigned-integer(<5bit-unsigned-integer>; 5) end;
define n-bit-unsigned-integer(<6bit-unsigned-integer>; 6) end;
define n-bit-unsigned-integer(<7bit-unsigned-integer>; 7) end;
define n-bit-unsigned-integer(<13bit-unsigned-integer>; 13) end;
define n-bit-unsigned-integer(<14bit-unsigned-integer>; 14) end;

define method parse-frame (frame-type :: subclass(<unsigned-integer-bit-frame>),
                           packet :: <byte-sequence>,
                           #key start :: <integer> = 0)
  => (value :: <integer>, next-unparsed :: <integer>)
  let result-size = frame-size(frame-type);
  if (packet.size * 8 < start + result-size)
    signal(make(<malformed-packet-error>))
  else
    let result = 0;
    for (i from 0 below size(packet))
      result := ash(result, 8) + packet[i];
    end;
    values(result, result-size + start);
  end;
end;

define method assemble-frame (frame :: <unsigned-integer-bit-frame>)
  => (packet :: <stretchy-byte-vector-subsequence>)
  assemble-frame-as(frame.object-class, frame.data)
end;

define method assemble-frame-as(frame-type :: subclass(<unsigned-integer-bit-frame>),
                                data :: <integer>)
 => (packet :: <byte-sequence>)
  let result-size = frame-size(frame-type);
  let result = make(<byte-sequence>, end: byte-offset(result-size + 7));
  assemble-frame-into-as(frame-type, data, result);
  result;
end;

define method assemble-frame-into-as (frame-type :: subclass(<unsigned-integer-bit-frame>),
                                      data :: <integer>,
                                      packet :: <stretchy-vector-subsequence>)
 => (res :: <integer>)
  let result-size = frame-size(frame-type);
  let subseq = subsequence(packet, length: result-size);
  encode-integer(data, subseq, result-size);
  result-size;
end;

define method as (class == <string>, frame :: <unsigned-integer-bit-frame>)
  => (string :: <string>)
  concatenate("0x",
              integer-to-string(frame.data,
                                base: 16,
                                size: byte-offset(frame-size(frame) + 7) * 2));
end;

define method read-frame (type :: subclass(<unsigned-integer-bit-frame>),
                          string :: <string>)
 => (res)
  let res = string-to-integer(string);
  if (res < 0 | res > 2 ^ (field-size(type) - 1))
    signal(make(<out-of-range-error>))
  end;
  res;
end;

define abstract class <fixed-size-byte-vector-frame> (<fixed-size-untranslated-leaf-frame>)
  slot data :: <byte-sequence>, required-init-keyword: data:;
end;

define macro n-byte-vector-definer
    { define n-byte-vector(?:name, ?n:*) end }
     => { define class "<" ## ?name ## ">" (<fixed-size-byte-vector-frame>)
          end;

          define inline method field-size (type == "<" ## ?name ## ">") => (length :: <integer>)
            ?n * 8;
          end; 

          define leaf-frame-constructor(?name) end;
}
end;

define sealed domain parse-frame (subclass(<fixed-size-byte-vector-frame>),
                                  <byte-sequence>);

define method parse-frame (frame-type :: subclass(<fixed-size-byte-vector-frame>),
                           packet :: <byte-sequence>,
                           #key start :: <integer> = 0)
  => (frame :: <fixed-size-byte-vector-frame>, next-unparsed :: <integer>)
  byte-aligned(start);
  let end-of-frame = start + field-size(frame-type);
  if (packet.size < byte-offset(end-of-frame))
    signal(make(<malformed-packet-error>))
  else
    values(make(frame-type,
                data: packet),
           end-of-frame)
  end;
end;

define method assemble-frame (frame :: <fixed-size-byte-vector-frame>) => (packet :: <byte-vector>)
  frame.data;
end;

define method assemble-frame-into (frame :: <fixed-size-byte-vector-frame>,
                                   packet :: <stretchy-byte-vector-subsequence>) => (res :: <integer>)
  copy-bytes(frame.data, 0, packet, 0, byte-offset(frame-size(frame)));
  frame-size(frame)
end;

define method as (class == <string>, frame :: <fixed-size-byte-vector-frame>) => (res :: <string>)
  let out-stream = make(<string-stream>, direction: #"output");
  block()
    hexdump(out-stream, frame.data);
    out-stream.stream-contents;
  cleanup
    close(out-stream)
  end
end;

define method read-frame (frame-type :: subclass(<fixed-size-byte-vector-frame>),
                          string :: <string>)
 => (res)
  make(frame-type,
       data: copy-sequence(string,
                           start: 0,
                           end: byte-offset(field-size(frame-type))));
end;

define method \= (frame1 :: <fixed-size-byte-vector-frame>,
                  frame2 :: <fixed-size-byte-vector-frame>)
 => (result :: <boolean>)
  frame1.data = frame2.data
end method;

define abstract class <big-endian-unsigned-integer-byte-frame> (<fixed-size-translated-leaf-frame>)
  //slot data :: <integer>, required-init-keyword: data:;
end;

define abstract class <little-endian-unsigned-integer-byte-frame> (<fixed-size-translated-leaf-frame>)
end;

define macro n-byte-unsigned-integer-definer
    { define n-byte-unsigned-integer(?:name; ?n:*) end }
     => { define class ?name ## "-big-endian-unsigned-integer>"
                 (<big-endian-unsigned-integer-byte-frame>)
            slot data :: limited(<integer>, min: 0, max: 2 ^ (8 * ?n) - 1),
              required-init-keyword: data:;
          end;
          
          define inline method high-level-type
              (low-level-type == ?name ## "-big-endian-unsigned-integer>")
            => (res :: <type>)
            limited(<integer>, min: 0, max: 2 ^ (8 * ?n) - 1);
          end;

          define inline method field-size (field == ?name ## "-big-endian-unsigned-integer>")
           => (length :: <integer>)
           ?n * 8
          end;


          define class ?name ## "-little-endian-unsigned-integer>"
                 (<little-endian-unsigned-integer-byte-frame>)
            slot data :: limited(<integer>, min: 0, max: 2 ^ (8 * ?n) - 1),
              required-init-keyword: data:;
          end;
          
          define inline method high-level-type
              (low-level-type == ?name ## "-little-endian-unsigned-integer>")
            => (res :: <type>)
            limited(<integer>, min: 0, max: 2 ^ (8 * ?n) - 1);
          end;

          define inline method field-size (field == ?name ## "-little-endian-unsigned-integer>")
           => (length :: <integer>)
           ?n * 8
          end; }
end;

define n-byte-unsigned-integer(<2byte; 2) end;
define n-byte-unsigned-integer(<3byte; 3) end;
//define n-byte-unsigned-integer(<4byte; 4) end;

define sealed domain parse-frame (subclass(<big-endian-unsigned-integer-byte-frame>),
                                  <byte-sequence>);

define method parse-frame (frame-type :: subclass(<big-endian-unsigned-integer-byte-frame>),
                           packet :: <byte-sequence>,
                           #key start :: <integer> = 0)
 => (value :: <integer>, next-unparsed :: <integer>)
 byte-aligned(start);
 let result-size = byte-offset(frame-size(frame-type));
 let byte-start = byte-offset(start);
 if (packet.size < byte-start + result-size)
   signal(make(<malformed-packet-error>))
 else
   let result = 0;
   for (i from byte-start below byte-start + result-size)
     result := packet[i] + ash(result, 8)
   end;
   values(result, start + 8 * result-size);
 end;
end;

define method assemble-frame (frame :: <big-endian-unsigned-integer-byte-frame>)
 => (packet :: <byte-vector>)
  assemble-frame-as(frame.object-class, frame.data);
end;

define method assemble-frame-as (frame-type :: subclass(<big-endian-unsigned-integer-byte-frame>),
                                 data :: <integer>)
  => (packet :: <byte-vector-subsequence>)
  let result = make(<stretchy-byte-vector-subsequence>, end: byte-offset(frame-size(frame-type)));
  assemble-frame-into-as(frame-type, data, result);
  result;
end;

define method assemble-frame-into-as (frame-type :: subclass(<big-endian-unsigned-integer-byte-frame>),
                                      data :: <integer>,
                                      packet :: <byte-vector-subsequence>) => (res :: <integer>)
  for (i from 0 below byte-offset(frame-size(frame-type)))
    packet[i] := logand(#xff, ash(data, - (frame-size(frame-type) - i * 8 - 8)));
  end;
  frame-size(frame-type)
end;

define method as (class == <string>, frame :: <big-endian-unsigned-integer-byte-frame>)
 => (string :: <string>)
 concatenate("0x", integer-to-string(frame.data,
                                     base: 16,
                                     size: ash(2 * frame-size(frame.object-class), -3)));
end;

define method read-frame (type :: subclass(<big-endian-unsigned-integer-byte-frame>),
                          string :: <string>)
 => (res)
  let res = string-to-integer(string);
  if (res < 0 | res > 2 ^ (field-size(type) - 1))
    signal(make(<out-of-range-error>))
  end;
  res;
end;

define sealed domain parse-frame (subclass(<little-endian-unsigned-integer-byte-frame>),
                                  <byte-sequence>);

define method parse-frame (frame-type :: subclass(<little-endian-unsigned-integer-byte-frame>),
                           packet :: <byte-sequence>,
                           #key start :: <integer> = 0)
 => (value :: <integer>, next-unparsed :: <integer>)
 byte-aligned(start);
 let result-size = byte-offset(frame-size(frame-type));
 let byte-start = byte-offset(start);
 if (packet.size < byte-start + result-size)
   signal(make(<malformed-packet-error>))
 else
   let result = 0;
   for (i from byte-start + result-size - 1 to byte-start by -1)
     result := packet[i] + ash(result, 8)
   end;
   values(result, start + 8 * result-size);
 end;
end;

define method assemble-frame (frame :: <little-endian-unsigned-integer-byte-frame>)
 => (packet :: <byte-vector>)
  assemble-frame-as(frame.object-class, frame.data);
end;

define method assemble-frame-as (frame-type :: subclass(<little-endian-unsigned-integer-byte-frame>),
                                 data :: <integer>)
  => (packet :: <stretchy-byte-vector-subsequence>)
  let result = make(<stretchy-byte-vector-subsequence>, end: byte-offset(frame-size(frame-type)));
  assemble-frame-into-as(frame-type, data, result);
  result;
end;

define method assemble-frame-into-as (frame-type :: subclass(<little-endian-unsigned-integer-byte-frame>),
                                      data :: <integer>,
                                      packet :: <stretchy-byte-vector-subsequence>)
  for (i from 0 below byte-offset(frame-size(frame-type)))
    packet[i] := logand(#xff, ash(data, - i * 8));
  end;
  frame-size(frame-type);
end;

define method as (class == <string>, frame :: <little-endian-unsigned-integer-byte-frame>)
 => (string :: <string>)
 concatenate("0x", integer-to-string(frame.data,
                                     base: 16,
                                     size: ash(2 * frame-size(frame.object-class), -3)));
end;

define method read-frame (type :: subclass(<little-endian-unsigned-integer-byte-frame>),
                          string :: <string>)
 => (res)
  let res = string-to-integer(string);
  if (res < 0 | res > 2 ^ (field-size(type) - 1))
    signal(make(<out-of-range-error>))
  end;
  res;
end;


define abstract class <variable-size-byte-vector> (<variable-size-untranslated-leaf-frame>)
  slot data :: <byte-sequence>, required-init-keyword: data:;
  slot parent :: false-or(<container-frame>) = #f, init-keyword: parent:;
end;

define method frame-size (frame :: <variable-size-byte-vector>) => (res :: <integer>)
  frame.data.size * 8
end;

define method parse-frame (frame-type :: subclass(<variable-size-byte-vector>),
                           packet :: <byte-sequence>,
                           #key start :: <integer> = 0,
                           parent)
 => (frame :: <variable-size-byte-vector>, next-unparsed :: <integer>)
 byte-aligned(start);
 if (packet.size < byte-offset(start))
   signal(make(<malformed-packet-error>))
 else
   values(make(frame-type,
               data: packet,
               parent: parent),
          start + packet.size * 8)
 end
end;

define method assemble-frame (frame :: <variable-size-byte-vector>)
 => (packet :: <byte-vector>)
 frame.data
end;

define method assemble-frame-into (frame :: <variable-size-byte-vector>,
                                   packet :: <stretchy-byte-vector-subsequence>) => (res :: <integer>)
  copy-bytes(frame.data, 0, packet, 0, frame.data.size);
  frame-size(frame)
end;

define class <raw-frame> (<variable-size-byte-vector>)
end;

define method as (class == <string>, frame :: <raw-frame>) => (res :: <string>)
  let out-stream = make(<string-stream>, direction: #"output");
  block()
    hexdump(out-stream, frame.data);
    out-stream.stream-contents;
  cleanup
    close(out-stream)
  end
end;

define method read-frame (type == <raw-frame>,
                          string :: <string>)
 => (res)
  make(<raw-frame>,
       data: copy-sequence(string));
end;


