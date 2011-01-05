module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

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
