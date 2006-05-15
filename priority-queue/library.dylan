module: dylan-user

define library priority-queue
  use common-dylan;

  export priority-queue;
end library;

define module priority-queue
  use common-dylan;

  export <priority-queue>, <priority-queueable-mixin>;
end module priority-queue;
