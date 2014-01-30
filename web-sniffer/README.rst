web-sniffer
===========

reimplementation of the graphical user interface of network night vision (which was running at some point on GTK and Windows) in JavaScript

External Dependencies
=====================

* `opendylan <https://opendylan.org>`__
* `http  <https://github.com/dylan-lang/http>`__
* `json <https://github.com/dylan-lang/json>`__
* `graph.js <https://github.com/hannesm/graph.js>`__

Installation
============

set ``OPEN_DYLAN_USER_REGISTRIES`` environment variable to include network-night-vision, http and json

adjust path in ``web-sniffer.dylan`` for the document root

compile: ``dylan-compiler -build web-sniffer``

put graph.js into the ``static/graph`` subdirectory

run: ``_build/bin/web-sniffer`` (you might want to do this as root to capture from network interfaces)
