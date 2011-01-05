Module:    dylan-user
Synopsis:  A brief description of the project.
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define library tcp-state-machine
  use common-dylan;
  use io;
  use state-machine;

  export tcp-state-machine;
end library tcp-state-machine;
