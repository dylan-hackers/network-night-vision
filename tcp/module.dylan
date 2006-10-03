Module:    dylan-user
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define module tcp
  use common-dylan, exclude: { close };
  use threads;

  use format-out;
  use standard-io;
  use streams, import: { read-line };
end module tcp;
