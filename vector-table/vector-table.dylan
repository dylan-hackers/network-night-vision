module: vector-table
Author: Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define sealed class <vector-table> (<table>)
end class;

define method table-protocol (table :: <vector-table>)
 => (test-function :: <function>, hash-function :: <function>)
  values(method (x, y) x = y end, vector-hash);
end method table-protocol; 

define method vector-hash (vector :: <fixed-size-byte-vector-frame>, state :: <hash-state>)
  => (id :: <integer>, state :: <hash-state>)
  vector-hash(vector.data, state);
end method;

define method vector-hash (vector :: <collection>, state :: <hash-state>)
  => (id :: <integer>, state :: <hash-state>)
  let hash = 0;
  for (number in vector)
    hash := hash + number;
  end for;
  values(hash, state);
end method;
