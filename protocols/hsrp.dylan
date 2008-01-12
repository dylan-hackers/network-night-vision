module: hsrp

//Cisco Hot Standby Router Protocol (HSRP) RFC 2281 
define protocol hsrp (container-frame)
  over <udp-frame> 1985;
  field version :: <unsigned-byte> = 0;
  /*
    0 Hello
    1 Coup
    2 Resign
  */
  field opcode :: <unsigned-byte> = 0;
  /*
    0 Initial
    1 Learn
    2 Listen
    4 Speak
    8 Standby
    16 Active
  */
  field state :: <unsigned-byte> = 16;
  field hello-time :: <unsigned-byte> = 3;
  field hold-time :: <unsigned-byte> = 10;
  field priority :: <unsigned-byte> = 120;
  field group :: <unsigned-byte> = 1;
  field reserved :: <unsigned-byte> = 0;
  //recommended default value 0x63 0x69 0x73 0x63 0x6F 0x00 0x00 0x00 
  field authentication-data :: <raw-frame>, static-length: 8 * 8;
  field virtual-ip :: <ipv4-address>;
end;


define method summary (frame :: <hsrp>) => (res :: <string>)
  if(frame.opcode = 0)
    if(frame.state = 0)
      format-to-string("HSRP v%= Hello (Initial)", frame.version)
    elseif(frame.state = 1)
      format-to-string("HSRP v%= Hello (Learn)", frame.version)
    elseif(frame.state = 2)
      format-to-string("HSRP v%= Hello (Listen)", frame.version)
    elseif(frame.state = 4)
      format-to-string("HSRP v%= Hello (Speak)", frame.version)
    elseif(frame.state = 8)
      format-to-string("HSRP v%= Hello (Standby)", frame.version)
    elseif(frame.state = 16)
      format-to-string("HSRP v%= Hello (Active)", frame.version)
    else
      format-to-string("HSRP v%= Hello state: %=",
	                frame.version,
			frame.state)
    end
  else
    format-to-string("HSRP v%= opcode: %= state: %=",
	             frame.version,
		     frame.opcode,
		     frame.state)
  end
end;
