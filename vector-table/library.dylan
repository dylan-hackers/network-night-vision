module: dylan-user
Author: Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define library vector-table
  use common-dylan;
  use packetizer;
  use collections, import: { table-extensions };

  export vector-table;
end;

define module vector-table
  use common-dylan;
  use packetizer;
  use table-extensions;

  export <vector-table>;
end;
