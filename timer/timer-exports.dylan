module: dylan-user

define library timer
  use common-dylan;
  use io;
  use priority-queue;
  use system;

  export timer;
end library;

define module timer
  use common-dylan;
  use format-out;
  use priority-queue;
  use date;
  use threads;

  export <timer>, cancel;
end module;
