module: dylan-user

define library dhcp-state-machine
  use dylan;
  use common-dylan;
  use state-machine;
  export dhcp-state-machine;
end;

define module dhcp-state-machine
  use dylan;
  use common-dylan;
  use state-machine;

  export <dhcp-client-state>, offer, xid,
    offer-setter, xid-setter;

  export <init-reboot>, <rebooting>,
    <requesting>, <init>,
    <selecting>, <rebinding>,
    <bound>, <renewing>, <dhcp-state>;
end;
