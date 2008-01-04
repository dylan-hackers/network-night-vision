module: logical-link
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define protocol link-control (header-frame)
  field dsap :: <unsigned-byte>;
  field ssap :: <unsigned-byte>;
  field control :: <unsigned-byte>;
  field organisation-code :: <3byte-big-endian-unsigned-integer>;
  layering field type-code :: <2byte-big-endian-unsigned-integer>;
  variably-typed-field payload,
    type-function: payload-type(frame);
end;

