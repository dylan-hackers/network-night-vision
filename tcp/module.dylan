Module:    dylan-user
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define module tcp
  use common-dylan, exclude: { close };

  use format-out;
  use standard-io;
  use streams, import: { read-line };

  export <tcp-dingens>, state, state-setter;

  export <tcp-state>, <closed>, <listen>,
    <syn-sent>, <syn-received>, <established>,
    <fin-wait1>, <fin-wait2>, <closing>,
    <time-wait>, <close-wait>, <last-ack>;

  export passive-open, active-open, close,
    syn-received, syn-ack-received, rst-received,
    fin-received, ack-received, fin-ack-received;
end module tcp;
