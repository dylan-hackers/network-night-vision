Module:    dylan-user
Copyright: (c) 2008 Dylan Hackers

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
    <pado-received>, <padr-sent>,
    <established>, <pppoe-state>;

  export <ppp-abstract-state-machine>;

  export <initial>, <starting>, <closed>, <stopped>, <closing>, <stopping>,
    <request-sent>, <ack-received>, <ack-sent>, <opened>, <ppp-state>;
end module;
