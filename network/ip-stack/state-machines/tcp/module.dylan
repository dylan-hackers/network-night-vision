Module:    dylan-user
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define module tcp-state-machine
  use common-dylan, exclude: { close };
  use threads;
  use format-out;
  use standard-io;
  use streams, import: { read-line };
  use state-machine;

  export <tcp-dingens>, state, lock;

  export <tcp-state>, <closed>, <listen>,
    <syn-sent>, <syn-received>, <established>,
    <fin-wait1>, <fin-wait2>, <closing>,
    <time-wait>, <close-wait>, <last-ack>;

  export <tcp-events>;

end module tcp-state-machine;
