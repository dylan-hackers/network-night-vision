module: dylan-user
author: Andreas Bogk, Hannes Mehnert
copyright: (c) 2006, All rights reserved. Free for non-commercial user

define library interfaces
  use common-dylan;
  use c-ffi;
  use io;
  use collection-extensions;
  use functional-dylan;
  use flow;
  use packetizer;

  export interfaces;
end;

define module interfaces
  use common-dylan;
  use c-ffi;
  use format-out;
  use standard-io;
  use subseq;
  use dylan-direct-c-ffi;
  use machine-words;
  use byte-vector;
  use flow;
  use packetizer, import: { unparsed-class, <ethernet-frame>, <frame>, assemble-frame };
  export <ethernet-interface>, interface-name;
end;

