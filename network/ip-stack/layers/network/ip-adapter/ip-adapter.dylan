module: ip-adapter
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define open layer ip-adapter (<layer>)
  inherited property administrative-state = #"up";
  property ip-address :: <cidr>;
  property mtu :: <integer> = 1524;
end;

define method read-as (type == <cidr>, value :: <string>) => (res)
  as(<cidr>, value);
end;


