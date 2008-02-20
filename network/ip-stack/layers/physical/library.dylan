module: dylan-user

define library physical-layer
  use common-dylan;
  use layer;
  export physical-layer;
end;

define module physical-layer
  use common-dylan;
  use new-layer;

  export <physical-layer>;
end;
