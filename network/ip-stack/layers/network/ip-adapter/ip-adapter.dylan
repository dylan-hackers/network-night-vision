module: ip-adapter
synopsis: 
author: 
copyright: 

define open layer ip-adapter (<layer>)
  inherited property administrative-state = #"up";
  property ip-address :: <cidr>;
  property mtu :: <integer> = 1524;
end;

define method read-as (type == <cidr>, value :: <string>) => (res)
  as(<cidr>, value);
end;


