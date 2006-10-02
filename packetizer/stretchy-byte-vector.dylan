module:packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved. Free for non-commercial use.


define class <out-of-bound-error> (<error>)
end;

define constant <stretchy-byte-vector> = limited(<stretchy-vector>, of: <byte>);

define abstract class <stretchy-vector-subsequence> (<vector>)
  constant slot real-data :: <stretchy-byte-vector> = make(<stretchy-byte-vector>),
    init-keyword: data:;
  constant slot start-index :: <integer> = 0, init-keyword: start:;
  constant slot end-index :: false-or(<integer>) = #f, init-keyword: end:;
end;

define method make (class == <stretchy-vector-subsequence>,
                    #next next-method,
                    #rest rest,
                    #key start, end: last, bit-start, bit-end,
                    #all-keys) => (res :: <stretchy-vector-subsequence>)
  if (bit-start & bit-start ~= 0)
    apply(make, <stretchy-byte-vector-subsequence-with-offset>, rest)
  else
    if (bit-end & bit-end ~= 0)
      apply(make, <stretchy-byte-vector-subsequence-with-offset>, rest)
    else
      apply(make, <stretchy-byte-vector-subsequence>, rest)
    end;
  end;
end;

define inline function check-values (start :: <integer>, length :: false-or(<integer>), last :: false-or(<integer>))
 => (start :: <integer>, last :: false-or(<integer>))
  if (last & length)
    error("only last or length can be provided!");
  end;
  let end-offset = if (last) last elseif (length) length + start else #f end;
  if (end-offset & ((end-offset < start) | (end-offset < 0)))
    signal(make(<out-of-bound-error>))
  end;
  if (start < 0)
    signal(make(<out-of-bound-error>))
  end;
  values(start, end-offset);
end;
define method subsequence (seq :: <stretchy-byte-vector-subsequence>,
                           #key start :: <integer> = 0,
                                length :: false-or(<integer>),
                                end: last :: false-or(<integer>))
 => (res :: <stretchy-vector-subsequence>)
  //assumption: start, length, last are in bits!
  let (start, end-offset) = check-values(start, length, last);
  let (start-byte :: <integer>, start-bit :: <integer>) = truncate/(start, 8);
  if (seq.end-index & ((seq.end-index < start-byte + seq.start-index)))
    signal(make(<out-of-bound-error>))
  end;
  let (last-byte :: false-or(<integer>), last-bit :: false-or(<integer>))
    = if (end-offset)
        truncate/(seq.start-index * 8 + end-offset, 8)
      else
        values(seq.end-index, #f)
      end;
  if ((end-offset) & (seq.end-index) & (seq.end-index < last-byte))
    signal(make(<out-of-bound-error>))
  end;
  make(<stretchy-vector-subsequence>,
       data: seq.real-data,
       start: start-byte + seq.start-index,
       bit-start: start-bit,
       end: if (last-byte) last-byte end,
       bit-end: if (last-bit) last-bit end);
end;

define inline function vs-fip-next-element 
    (c :: <stretchy-vector-subsequence>, s :: <integer>) => (result :: <integer>);
  s + 1;
end function;

define inline function vs-fip-done? 
    (c :: <stretchy-vector-subsequence>, s :: <integer>, l :: <integer>)
 => (done :: <boolean>);
  s >= l;
end function;

define inline function vs-fip-current-key 
    (c :: <stretchy-vector-subsequence>, s :: <integer>) => (result :: <integer>);
  s;
end function;

define inline function vs-fip-copy-state
    (c :: <stretchy-vector-subsequence>, s :: <integer>) => (result :: <integer>);
  s;
end function;


define sealed class <stretchy-byte-vector-subsequence> (<stretchy-vector-subsequence>)
end;

define inline function real-sbv-element
    (c :: <stretchy-byte-vector-subsequence>, key :: <integer>) => (result :: <byte>)
  c.real-data[key];
end;

define inline function real-sbv-element-setter
    (value :: <byte>, c :: <stretchy-byte-vector-subsequence>, key :: <integer>) => (result :: <byte>)
  c.real-data[key] := value;
end;

define inline method forward-iteration-protocol (seq :: <stretchy-byte-vector-subsequence>)
 => (initial-state :: <object>, limit :: <object>, next-state :: <function>,
     finished-state? :: <function>, current-key :: <function>,
     current-element :: <function>, current-element-setter :: <function>,
     copy-state :: <function>);
  values(seq.start-index, seq.end-index | seq.real-data.size, vs-fip-next-element,
         vs-fip-done?, vs-fip-current-key, real-sbv-element,
         real-sbv-element-setter, vs-fip-copy-state)
end;

define inline method as (class == <stretchy-byte-vector-subsequence>, data :: <byte-vector>)
 => (res :: <stretchy-byte-vector-subsequence>)
  make(<stretchy-byte-vector-subsequence>, data: as(<stretchy-byte-vector>, data));
end;

define inline method as (class == <stretchy-byte-vector-subsequence>, data :: <collection>)
 => (res :: <stretchy-byte-vector-subsequence>)
  as(<stretchy-byte-vector-subsequence>, as(<byte-vector>, data));
end;

define inline method size (c :: <stretchy-byte-vector-subsequence>) => (result :: <integer>);
  let res = c.real-data.size - c.start-index;
  if (res > 0)
    if (c.end-index)
      min(res, c.end-index - c.start-index)
    else
      res
    end
  else
    0
  end
end method size;

define inline function check-sbv-range
 (seq :: <stretchy-byte-vector-subsequence>, key :: <integer>) => ()
  if (key < 0)
    signal(make(<out-of-bound-error>))
  end;
  if (seq.end-index & (key >= (seq.end-index - seq.start-index)))
    signal(make(<out-of-bound-error>))
  end;
end;
define inline method element (seq :: <stretchy-byte-vector-subsequence>,
                              key :: <integer>, #key default) => (res :: <byte>)
  check-sbv-range(seq, key);
  seq.real-data[key + seq.start-index];
end;

define inline method element-setter (value :: <byte>, seq :: <stretchy-byte-vector-subsequence>,
                                     key :: <integer>) => (res :: <byte>)
  check-sbv-range(seq, key);
  seq.real-data[key + seq.start-index] := value;
end;

define class <bit> (<object>)
//NYI
end;
define class <stretchy-bit-vector-subsequence> (<stretchy-vector-subsequence>)
end;

define inline method size(c :: <stretchy-bit-vector-subsequence>) => (result :: <integer>);
  let res = c.real-data.size * 8 - c.start-index;
  if (res > 0)
    if (c.end-index)
      min(res, c.end-index - c.start-index)
    else
      res
    end
  else
    0
  end
end method size;

define inline method element (seq :: <stretchy-bit-vector-subsequence>,
                              key :: <integer>, #key default) => (res :: <bit>)
  if ((key > seq.start-index) & (seq.end-index & (key < seq.end-index)))
    let (byte-offset, bit-offset) = truncate/(seq.start-index + key, 8);
    logand(1, ash(seq.real-data[byte-offset], - (7 - bit-offset)))
  else
    error("out of bound")
  end
end;

define inline method element-setter (value :: <bit>, seq :: <stretchy-bit-vector-subsequence>,
                                     key :: <integer>) => (res :: <bit>)
  if ((key > seq.start-index) & (seq.end-index & (key < seq.end-index)))
    let (byte-offset, bit-offset) = truncate/(seq.start-index + key, 8);
    let mask = lognot(ash(1, 7 - bit-offset));

    seq.real-data[byte-offset] := logior(logand(mask, seq.real-data[byte-offset]),
                                         ash(value, 7 - bit-offset));
  else
    error("out of bound")
  end
end;

define class <stretchy-byte-vector-subsequence-with-offset> (<stretchy-vector-subsequence>)
  constant slot bit-start-index :: <integer> = 0, init-keyword: bit-start:;
  constant slot bit-end-index :: <integer> = 8, init-keyword: bit-end:;
end;

define method make (class == <stretchy-byte-vector-subsequence-with-offset>,
                    #next next-method,
                    #rest rest,
                    #key bit-end, end: last,
                    #all-keys) => (res :: <stretchy-byte-vector-subsequence-with-offset>)
  unless (bit-end)
    replace-arg(rest, #"bit-end", 8);
  end;
  if (bit-end & bit-end = 0)
    replace-arg(rest, #"bit-end", 8);
    replace-arg(rest, #"end", last - 1);
  end;
  apply(next-method, class, rest)
end;

define inline function replace-arg (list :: <vector>, key :: <symbol>, value :: <object>)
 => (res :: <vector>)
  for (i from 0 below list.size by 2)
    if (list[i] = key)
      list[i + 1] := value
    end;
  end;
  list;
end;
define inline method subsequence (seq :: <stretchy-byte-vector-subsequence-with-offset>,
                                  #key start :: <integer> = 0,
                                       length :: false-or(<integer>),
                                       end: last :: false-or(<integer>))
 => (seq :: <stretchy-vector-subsequence>)
  let (start, end-offset) = check-values(start, length, last);
  let old-start = seq.start-index * 8 + seq.bit-start-index;
  let (start-byte :: <integer>, start-bit :: <integer>) = truncate/(start + old-start, 8);
  let old-end = if (seq.end-index) seq.end-index * 8 + seq.bit-end-index end;
  if (old-end & ((old-end < start + old-start)))
    signal(make(<out-of-bound-error>))
  end;
  let new-end
    = if (end-offset)
        old-start + end-offset
      elseif (old-end)
        old-end
      else
        #f
      end;
  if ((new-end) & (old-end) & (old-end < new-end))
    signal(make(<out-of-bound-error>))
  end;
  let (last-byte :: false-or(<integer>), last-bit :: false-or(<integer>))
    = if (new-end) truncate/(new-end, 8) else values(#f, #f) end; 
  make(<stretchy-vector-subsequence>,
       data: seq.real-data,
       start: start-byte,
       bit-start: start-bit,
       end: if (last-byte) last-byte end,
       bit-end: if (last-bit) last-bit end);
end;

define inline method size(c :: <stretchy-byte-vector-subsequence-with-offset>)
 => (result :: <integer>);
  let fudge-factor = if (c.bit-start-index >= c.bit-end-index) 0 else 1 end;
  let res = c.real-data.size - c.start-index + fudge-factor;
  if (res > 0)
    if (c.end-index)
      min(res, max(c.end-index - c.start-index + fudge-factor, 0))
    else
      res - fudge-factor
    end
  else
    0
  end
end method size;

define inline function check-sbvwo-range (seq :: <stretchy-byte-vector-subsequence-with-offset>, key :: <integer>)
  if (key < 0)
    signal(make(<out-of-bound-error>));
  end;
  if (seq.end-index & (key >= seq.size))
    signal(make(<out-of-bound-error>));
  end;
end;

define inline function real-sbvwo-element
    (c :: <stretchy-byte-vector-subsequence-with-offset>, key :: <integer>) => (result :: <byte>)
  element(c, key - c.start-index);
end;

define inline function real-sbvwo-element-setter
    (value :: <byte>, c :: <stretchy-byte-vector-subsequence-with-offset>, key :: <integer>) => (result :: <byte>)
  element-setter(value, c, key - c.start-index);
end;

define inline method forward-iteration-protocol (seq :: <stretchy-byte-vector-subsequence-with-offset>)
 => (initial-state :: <object>, limit :: <object>, next-state :: <function>,
     finished-state? :: <function>, current-key :: <function>,
     current-element :: <function>, current-element-setter :: <function>,
     copy-state :: <function>);
  values(seq.start-index, seq.end-index | seq.real-data.size, vs-fip-next-element,
         vs-fip-done?, vs-fip-current-key, real-sbvwo-element,
         real-sbvwo-element-setter, vs-fip-copy-state)
end;

define inline method element (seq :: <stretchy-byte-vector-subsequence-with-offset>,
                              key :: <integer>, #key default) => (res :: <byte>)
  check-sbvwo-range(seq, key);
  if (key = seq.size - 1)
    //last element
    if (seq.bit-start-index >= seq.bit-end-index)
      //need to get 2 bytes
      ash(logand(ash(#xff, - seq.bit-start-index), seq.real-data[key + seq.start-index]), seq.bit-end-index)
       + ash(seq.real-data[key + seq.start-index + 1], - (8 - seq.bit-end-index));
    else
      logand(ash(seq.real-data[key + seq.start-index], - (8 - seq.bit-end-index)),
             ash(#xff, - (8 - (seq.bit-end-index - seq.bit-start-index))))
    end;
  else
    //need to get 2 bytes, and shift them correctly
    if (seq.bit-start-index ~= 0)
      ash(logand(ash(#xff, - seq.bit-start-index), seq.real-data[key + seq.start-index]), seq.bit-start-index)
        + ash(seq.real-data[key + seq.start-index + 1], - (8 - seq.bit-start-index));
    else
      seq.real-data[key + seq.start-index]
    end;
  end;
end;

define inline method element-setter (value :: <byte>, seq :: <stretchy-byte-vector-subsequence-with-offset>,
                                     key :: <integer>) => (res :: <byte>)
  check-sbvwo-range(seq, key);
  let first-byte = key + seq.start-index;
  if (key = seq.size - 1)
    //last element
    if (seq.bit-start-index >= seq.bit-end-index)
      let mask = lognot(ash(#xff, - seq.bit-start-index));
      seq.real-data[first-byte] := logior(logand(seq.real-data[first-byte], mask),
                                          ash(value, - seq.bit-end-index));
      let other-mask = ash(#xff, - seq.bit-end-index);
      seq.real-data[first-byte + 1] := logior(logand(seq.real-data[first-byte + 1], other-mask),
                                              logand(#xff, ash(value, 8 - seq.bit-end-index)))
    else
      let mask = ash(ash(#xff, - (seq.bit-end-index - seq.bit-start-index)), seq.bit-start-index);
      seq.real-data[first-byte] := logior(logand(seq.real-data[first-byte], mask),
                                          ash(value, 8 - seq.bit-end-index))
    end;
  else
    if (seq.bit-start-index ~= 0)
      seq.real-data[first-byte] := logior(logand(seq.real-data[first-byte],
                                                 lognot(ash(#xff, - seq.bit-start-index))),
                                          ash(value, - (8 - seq.bit-start-index)));
      seq.real-data[first-byte + 1] := logior(logand(seq.real-data[first-byte + 1],
                                                     ash(#xff, - seq.bit-start-index)),
                                              logand(#xff, ash(value, 8 - seq.bit-start-index)));
    else
      seq.real-data[first-byte] := value;
    end;
  end;
  value;
end;


define inline method encode-integer (value :: <integer>, seq :: <stretchy-byte-vector-subsequence-with-offset>, count :: <integer>)
  if (value > 2 ^ count - 1)
    error("value to big for n bits")
  end;
  if (seq.end-index & (((seq.end-index - seq.start-index) * 8 - seq.bit-start-index + seq.bit-end-index) < count))
    signal(make(<out-of-bound-error>))
  end;
  let needed-size = ceiling/(count + seq.bit-start-index + seq.start-index * 8, 8);
  if (seq.real-data.size < needed-size)
    seq.real-data.size := needed-size
  end;
  let (fullbytes, bits) = truncate/(count - 8 + seq.bit-start-index, 8);
  if ((fullbytes = 0) & (bits < 0))
    let mask = ash(ash(#xff, - (count - seq.bit-start-index)), seq.bit-start-index);
    seq.real-data[0] := logior(logand(seq.real-data[0], mask),
                               ash(value, 8 - (count - seq.bit-start-index)));
  else
    if (seq.bit-start-index = 0)
      seq.real-data[0] := logand(#xff, ash(value, - (count - 8)));
    else
      //write first element
      seq.real-data[0] := logior(logand(seq.real-data[0],
                                        lognot(ash(#xff, - seq.bit-start-index))),
                                 logand(#xff, ash(value, - (count - 8 + seq.bit-start-index))));
    end;
    //loop other elements
    for (i from 1 below fullbytes + 1)
      seq.real-data[i] := logand(#xff, ash(value, - (count - i * 8 + seq.bit-start-index)));
    end;
    //last element
    if ((bits > 0) & (fullbytes >= 0))
      seq.real-data[fullbytes + 1] := logior(logand(seq.real-data[fullbytes + 1],
                                                    ash(#xff, - bits)),
                                             logand(logand(#xff, lognot(ash(#xff, - bits))),
                                                    ash(value, 8 - bits)));
    end;
  end;
end;

