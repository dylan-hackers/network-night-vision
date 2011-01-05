module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define library physical-layer
  use common-dylan;
  use layer;
  export physical-layer;
end;

define module physical-layer
  use common-dylan;
  use new-layer;

  export <physical-layer>;
end;
