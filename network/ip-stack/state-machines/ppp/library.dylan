Module:    dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define library ppp-state-machine
  use dylan;
  use common-dylan;
  use state-machine;
  export ppp-state-machine;
end library;

define module ppp-state-machine
  use dylan;
  use common-dylan;
  use state-machine;

  export <pppoe-client-abstract-state-machine>;

  export <down>,  <padi-sent>,
    <padr-sent>,
    <established>, <pppoe-state>,
    <waiting-for-carrier>, <waiting-for-administrative-up>;

  export <ppp-abstract-state-machine>;

  export <initial>, <starting>, <closed>, <stopped>, <closing>, <stopping>,
    <request-sent>, <ack-received>, <ack-sent>, <opened>, <ppp-state>;
end module;
