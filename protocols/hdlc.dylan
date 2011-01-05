module: hdlc
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

// Cisco High-Level Data Link Control
// http://www.nethelp.no/net/cisco-hdlc.txt
define protocol cisco-hdlc-frame (header-frame)
  summary "Cisco HDLC";
  enum field address :: <unsigned-byte> = #x8f,
    mappings: { #x0f <=> #"unicast",
                #x8f <=> #"multicast" };
  field control :: <unsigned-byte> = 0;
  layering field protocol :: <2byte-big-endian-unsigned-integer> = #x800;
  variably-typed-field payload,
    type-function: payload-type(frame);
end;

// Serial Line Address Resolution Protocol
define abstract protocol slarp (variably-typed-container-frame)
  over <cisco-hdlc-frame> #x8035;
  // layering field packet-type :: <big-endian-unsigned-integer-4byte> = 2;
  field packet-type-first :: <unsigned-byte> = 0;
  layering field packet-type :: <3byte-big-endian-unsigned-integer> = 2;
end;

define method summary (frame :: <slarp>) => (res :: <string>)
  if(frame.packet-type = 0)
    format-to-string("SLARP (request)")
  elseif(frame.packet-type = 1)
    format-to-string("SLARP (reply)")
  elseif(frame.packet-type = 2)
    format-to-string("SLARP (line keepalive)")
  else
    format-to-string("SLARP (packet-type: %=", frame.packet-type)
  end;
end;

define protocol slarp-address-resolution (slarp)
  over <slarp> 0;
  over <slarp> 1;
//  field address :: <ipv4-address>;
//  field mask :: <ipv4-address>;
//  field unused :: <2byte-big-endian-unsigned-integer> = 0;
end;

define protocol slarp-line-keepalive (slarp)
  over <slarp> 2;
  field mysequence :: <big-endian-unsigned-integer-4byte>;
  field yoursequence :: <big-endian-unsigned-integer-4byte>;
  field reliability :: <2byte-big-endian-unsigned-integer> = #xffff;
end;
