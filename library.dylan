Module:    dylan-user
Synopsis:  State Machine definition macros
Author:    Hannes Mehnert
Copyright: (C) 2007,  All rights reversed.

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
