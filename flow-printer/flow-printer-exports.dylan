module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define library flow-printer
  use common-dylan;
  use io;
  use flow;
  use graphviz-renderer;

  export flow-printer;
end library;

define module flow-printer
  use common-dylan;
  use format-out;
  use format;
  use streams;
  use flow;
  use graphviz-renderer, prefix: "graphviz-";

  export print-flow;
end module;
