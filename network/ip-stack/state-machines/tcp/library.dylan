Module:    dylan-user
Synopsis:  A brief description of the project.
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define library tcp-state-machine
  use common-dylan;
  use io;
  use state-machine;

  export tcp-state-machine;
end library tcp-state-machine;

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
