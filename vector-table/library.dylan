module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library vector-table
  use common-dylan;
  use binary-data;
  use collections, import: { table-extensions };

  export vector-table;
end;

define module vector-table
  use common-dylan;
  use binary-data;
  use table-extensions;

  export <vector-table>;
end;
