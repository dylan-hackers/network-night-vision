module: ip-adapter
synopsis: 
author: 
copyright: 

define open layer ip-adapter (<layer>)
  property administrative-state :: <symbol> = #"up";
  system property running-state :: <symbol> = #"down";
  property ip-address :: <cidr>;
  property mtu :: <integer> = 1524;
end;

define method read-as (type == <cidr>, value :: <string>) => (res)
  as(<cidr>, value);
end;


