module: hex-view

define function hex(integer :: <integer>, #key size)
 => (string :: <string>)
  integer-to-string(integer, base: 16, size: size)
end function hex;

/*
define method hexdump (sequence :: <sequence>) => (dump :: <string>)
  let stream = make(<string-stream>, direction: #"output");
  block()
    for (byte in sequence,
         index from 0)
      if(modulo(index, 16) == 0)
        format(stream, "%s  ", hex(index, size: 4))
      end;
      format(stream, "%s", hex(byte, size: 2));
      if(modulo(index, 16) == 15 
        | (index == sequence.size - 1 & sequence.size > 16))
        format(stream, "\n")
      elseif(modulo(index, 16) == 7)
        format(stream, "  ");
      else
        format(stream, " ");
      end if;
    end for;
    stream-contents(stream);
  cleanup
    close(stream)
  end
end method hexdump;
*/

define method hexdump (sequence :: <sequence>) => (dump :: <string>)
  let stream = make(<string-stream>, direction: #"output");
  block()
    for (index from 0 below sequence.size by 16)
      let rest-bytes = min(16, sequence.size - index);
      format(stream, "%s  ", hex(index, size: 4));
      for (byte-index from 0 below rest-bytes)
        format(stream, "%s", hex(sequence[index + byte-index], size: 2));
        if(modulo(byte-index, 16) == 7)
          format(stream, "  ");
        else
          format(stream, " ");
        end if;
      end for;
      for (byte-index from rest-bytes below 16)
        if(modulo(byte-index, 16) == 7)
          format(stream, "    ");
        else
          format(stream, "   ");
        end if;
      end for;
      format(stream, "  ");
      for (byte-index from 0 below rest-bytes)
        let byte = sequence[index + byte-index];
        if (byte >= 32 & byte < 128) // lame, I know
          format(stream, "%s", as(<character>, byte))
        else
          format(stream, ".")
        end;
        if(modulo(byte-index, 16) == 7)
          format(stream, " ");
        end;
      end for;
      format(stream, "\n");
    end for;
    stream-contents(stream);
  cleanup
    close(stream)
  end
end method hexdump;


define method set-highlight (frame, start-offset, end-offset)
  let window :: <basic-window> = frame-window(frame);
  let name = "hex view";
  let editor = frame-editor(frame);
  let buffer = find-buffer(editor, name);
  if (buffer)
    let (start-line, start-rest) = floor/(floor/(start-offset, 8), 16);
    let (end-line, end-rest) = floor/(floor/(end-offset - 1, 8), 16);
    let start-pos = 6 + start-rest * 3 + if (start-rest >= 8) 1 else 0 end;
    let end-pos = 8 + end-rest * 3 + if (end-rest >= 8) 1 else 0 end;
    let start-pos2 = start-rest + 57 + if (start-rest >= 8) 1 else 0 end;
    let end-pos2 = end-rest + 58 + if (end-rest >= 8) 1 else 0 end;

    format-out("%= %=, %= %=, %= %=\n", start-offset, end-offset, start-line, start-pos, end-line, end-pos);

    For (i from 0,
        line = buffer.buffer-start-node.node-section.section-start-line then line.line-next,
        while: line)
      line.line-style-changes := #[];
      if (end-offset - start-offset > 0)
        if ((start-line < i) & (end-line >= i))
          line.line-style-changes := vector(make(<style-change>,
                                                 index: 6,
                                                 font: window-default-bold-font(window)));
          line.line-style-changes := add!(line.line-style-changes,
                                          make(<style-change>,
                                                 index: 58,
                                                 font: window-default-bold-font(window))); 
       end;
        if (end-line = i)
          line.line-style-changes := add!(line.line-style-changes,
                                          make(<style-change>,
                                               index: end-pos,
                                               font: window-default-font(window)));
          line.line-style-changes := add!(line.line-style-changes,
                                          make(<style-change>,
                                               index: end-pos2,
                                               font: window-default-font(window)));
        end;
        if (start-line = i)
          line.line-style-changes := add!(line.line-style-changes,
                                          make(<style-change>,
                                               index: start-pos,
                                               font: window-default-bold-font(window)));
          line.line-style-changes := add!(line.line-style-changes,
                                          make(<style-change>,
                                                 index: 57,
                                                 font: window-default-font(window))); 
          line.line-style-changes := add!(line.line-style-changes,
                                          make(<style-change>,
                                               index: start-pos2,
                                               font: window-default-bold-font(window)));
        end;
      end;
    end;
    select-buffer-in-appropriate-window(window, buffer);
    initialize-redisplay-for-buffer(window, buffer);
    frame-last-command-type(frame) := #"display";
  end;
end;

define method show-hexdump (frame :: <basic-editor-frame>,
                           text)
  let lines = split(hexdump(text), '\n');

  if (lines.size = 0)
    lines := #("");
  end;

  let window :: <basic-window> = frame-window(frame);
  let name = "hex view";
  let editor = frame-editor(frame);
  let buffer = find-buffer(editor, name)
               | make-empty-buffer(<simple-display-buffer>,
                                   name:       name,
                                   major-mode: find-mode(<text-mode>),
                                   read-only?: #t,
                                   editor:     editor);
  let section = make(<section>, start-line: #f, end-line: #f);
  let first-line :: false-or(<basic-line>) = #f;
  let last-line  :: false-or(<basic-line>) = #f;
  for (line in lines)
    let line = make(<rich-text-line>,
                    contents: line,
                    length: size(line),
                    section: section);
    unless (first-line)
      first-line := line
    end;
    line-previous(line) := last-line;
    when (last-line)
      line-next(last-line) := line
    end;
    last-line := line;
  end;
  section-start-line(section) := first-line;
  section-end-line(section)   := last-line;
  let node = make-section-node(buffer, section);
  node-buffer(node)         := buffer;
  section-nodes(section)    := list(node);
  buffer-start-node(buffer) := node;
  buffer-end-node(buffer)   := node;
  select-buffer-in-appropriate-window(window, buffer);
  initialize-redisplay-for-buffer(window, buffer);
  frame-last-command-type(frame) := #"display";
end;
