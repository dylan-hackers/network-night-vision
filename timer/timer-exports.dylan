module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

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

  export <timer>, cancel, <recurrent-timer>;
end module;
