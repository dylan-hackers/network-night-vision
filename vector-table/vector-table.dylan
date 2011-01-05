module: vector-table
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define sealed class <vector-table> (<table>)
end class;

define method table-protocol (my-table :: <vector-table>)
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
