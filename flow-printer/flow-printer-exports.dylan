module: dylan-user

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
