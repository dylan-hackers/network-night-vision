module: icmp

define protocol icmp-frame (header-frame)
  summary "ICMP type %= code %=", icmp-type, code;
  over <ipv4-frame> 1;
  over <ipv6-frame> #x3a;
  field icmp-type :: <unsigned-byte>;
  field code :: <unsigned-byte>;
  field checksum :: <2byte-big-endian-unsigned-integer> = 0;
  field payload :: <raw-frame>;
end;

define method fixup! (frame :: <unparsed-icmp-frame>,
                      #next next-method)
  frame.checksum := calculate-checksum(frame.packet, frame.packet.size);
  next-method();
end;


