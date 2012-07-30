Welcome to Network Night Vision
======================

Screenshot is available here: http://opendylan.org/~hannes/gui-sniffer.png

This is network night vision, consisting of a domain-specific language for
describing binary protocols, which generates readers and writers into a
high-level object.

The overall goal is to be able to write packet and protocol definitions abstractly,
and then write the logics of protocols in a concise way.

There is even a GUI, similar to Wireshark, but with a shell to setup your layering.

This project used ideas from the click modular router (http://www.read.cs.ucla.edu/click/Click), defstorage, scapy (http://www.secdev.org/projects/scapy/), wireshark (http://www.wireshark.org/) and others.

There are two documents about this project:

* Secure networking [2006] - http://opendylan.org/~hannes/secure-networking.pdf
* A domain-specific language for manipulation of binary data in Dylan [2007] - http://opendylan.org/~hannes/ilc07-final.pdf

Building
======================

* get an opendylan compiler from http://opendylan.org/download/
* opendylan source code https://github.com/dylan-lang/opendylan (including command-line-parser and regular-expressions)
* monday https://github.com/dylan-lang/monday
* pcap implementation (on FreeBSD, MacOSX, Win32 - be sure to download the developer version from https://www.winpcap.org/devel.htm ), raw sockets on Linux

Eiher in the IDE open the project gui-sniffer, or use the command line:
::

  dylan-compiler -build sniffer

