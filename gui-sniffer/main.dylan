module: gui-sniffer

define function main()
  initialize-icons();
  let gui-sniffer = make(<gui-sniffer-frame>);
  set-frame-size(gui-sniffer, 1024, 768);
  deuce/frame-window(gui-sniffer) := gui-sniffer.packet-hex-dump;
  deuce/*editor-frame* := gui-sniffer;
  deuce/*buffer* := deuce/make-initial-buffer();
  deuce/select-buffer(frame-window(gui-sniffer), deuce/*buffer*);
  command-enabled?(close-interface, gui-sniffer) := #f;
  gadget-enabled?(gui-sniffer.stop-button) := #f;
  start-frame(gui-sniffer);
end;

main()

