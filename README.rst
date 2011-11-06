Welcome to Network Night Vision
======================

This is network night vision, consisting of a domain-specific language for
describing binary protocols, which generates readers and writers into a
high-level object.

The overall goal is to be able to write packet and protocol definitions abstractly,
and then write the logics of protocols in a concise way.

There is even a GUI, similar to Wireshark, but with a shell to setup your layering.

This project used ideas from the click modular router project, defstorage, scapy,
wireshark and most likely others.

There are two documents about this project:
* Secure networking [2006] - http://opendylan.org/~hannes/secure-networking.pdf
* A domain-specific language for manipulation of binary data in Dylan [2007] - http://www.opendylan.org/~hannes/ilc07.pdf

Building
======================

 first get Opendylan from http://www.opendylan.org
 you will also need the source, https://github.com/dylan-lang/opendylan
 and monday https://github.com/dylan-lang/monday
 and command-line-parser https://github.com/dylan-lang/command-line-parser
 and a pcap implementation (on FreeBSD, MacOSX, Win32), raw sockets on Linux

Eiher in the IDE open the project gui-sniffer, or use the command line:
::

  opendylan -build sniffer

