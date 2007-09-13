Module:    dylan-user
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define library network-interfaces
  use common-dylan;
  use functional-dylan;
  use network;
  use C-FFI;
  use io;
  use collection-extensions;
  use flow;
  use packetizer;
  use protocols, import: { ethernet };

  export network-interfaces;
end library network-interfaces;
