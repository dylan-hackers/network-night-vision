module: logical-link
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define protocol link-control (header-frame)
  field dsap :: <unsigned-byte>;
  field ssap :: <unsigned-byte>;
  field control :: <unsigned-byte>;
  field organisation-code :: <3byte-big-endian-unsigned-integer>;
  layering field type-code :: <2byte-big-endian-unsigned-integer>;
  variably-typed-field payload,
    type-function: payload-type(frame);
end;

