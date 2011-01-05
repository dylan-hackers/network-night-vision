Module:    dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define library state-machine
  use common-dylan;
  use system;
  use io;

  export state-machine;
end library state-machine;

define module state-machine
  use common-dylan;
  use threads;
  use format-out;

  export <protocol-state>,
    singleton-class-definer,
    states,
    next-state,
    state-transition-rule-definer;

  export <protocol-state-encapsulation>,
    lock, state,
    process-event, state-transition;
end module state-machine;
