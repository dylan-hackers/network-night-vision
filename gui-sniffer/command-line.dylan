module: command-line

define open class <nnv-shell-mode> (<shell-mode>)
end class <nnv-shell-mode>;

define method mode-name
    (mode :: <nnv-shell-mode>) => (name :: <byte-string>)
  "NNV shell"
end method mode-name;

define method shell-input-complete?
    (mode :: <nnv-shell-mode>,
     buffer :: <basic-shell-buffer>, section :: <basic-shell-section>)
 => (complete? :: <boolean>, message :: false-or(<string>))
  let text = as(<string>, section);
  let is-complete? = #f;
  let message = #f;
  block()
    let (command, complete?, text) 
      = parse-command-line(frame-window(*editor-frame*).command-line-server, text); 
    if (complete?)
      is-complete? := #t;
    end
  exception (e :: <condition>)
    message := condition-to-string(e);
  end;
  values(is-complete?, message)
end method shell-input-complete?;

define method do-process-shell-input
    (mode :: <nnv-shell-mode>,
     buffer :: <basic-shell-buffer>, section :: <basic-shell-section>,
     #key window = frame-window(*editor-frame*)) => ()
  let text = as(<string>, section);
  let bp = line-end(section-end-line(section));
  shell-execute-code(window, text, bp);
  move-point!(bp, window: window);
  queue-redisplay(window, $display-text);
  redisplay-window(window);
end method do-process-shell-input;

define method shell-execute-code
    (pane :: <nnv-shell-gadget>, command-line :: <string>, bp :: <basic-bp>) => ()
  let server = pane.command-line-server;
//  let debugger? = release-internal?();
  let stream = server.server-output-stream;
  let buffer = pane.window-buffer;
  stream-position(stream) := buffer.interval-end-bp;
  block ()
    let handler (<serious-condition>)
      = method (condition :: <serious-condition>, next-handler :: <function>)
	  if (#t /* debugger? */)
	    next-handler()
	  else
	    display-condition(server.server-context, condition);
	    abort();
	  end
	end;
    let exit? = execute-command-line(server, command-line);
    // exit? & exit-frame(sheet-frame(pane))
  exception (<abort>)
    #f
  end
end method shell-execute-code;


define variable *nnv-shell-count* :: <integer> = 0;

define method make-shell
    (#key name, anonymous? = #f,
	  buffer-class  = <simple-shell-buffer>,
	  major-mode    = find-mode(<nnv-shell-mode>),
	  section-class = <simple-shell-section>,
	  editor        = $nnv-editor)
 => (buffer :: <basic-shell-buffer>)
  unless (name)
    inc!(*nnv-shell-count*);
    name := format-to-string("NNV shell %d", *nnv-shell-count*)
  end;
  let buffer = make-empty-buffer(buffer-class,
                                 name:       name,
                                 major-mode: major-mode,
                                 anonymous?: anonymous?,
                                 section-class: section-class,
                                 editor: editor);
  let node = make-empty-section-node(buffer);
  add-node!(buffer, node, after: #"start");
  interval-read-only?(node) := #t;
  buffer
end method make-shell;

define class <nnv-editor> (<basic-editor>) end;
define constant $nnv-editor :: <nnv-editor> = make(<nnv-editor>);
define class <nnv-shell-gadget> (<deuce-gadget>, <deuce-pane>)
  slot command-line-server :: false-or(<command-line-server>);
  keyword editor: = $nnv-editor;
end;

define function make-nnv-shell-pane
    (#rest initargs,
     #key context,
          class = <nnv-shell-gadget>,
          frame, buffer, #all-keys)
 => (window :: <nnv-shell-gadget>)
  let window = apply(make, class, initargs);
  dynamic-bind (*editor-frame* = window)
    let buffer = buffer | make-shell();
    let stream
      = make(<repainting-interval-stream>,
             interval: buffer,
             window: window,
             direction: #"output");
    stream-position(stream) := buffer.buffer-start-node.interval-end-bp;
    let server
      = make-command-line-server
        (real-context: context,
         input-stream: stream,	// ignored, so this is safe!
         output-stream: stream);
    window.command-line-server := server;
    dynamic-bind (*buffer* = buffer)
      select-buffer(window, buffer)
    end;
  end;
  window
end function;


define class <nnv-context> (<server-context>)
  keyword banner: = "Network Night Vision";
  slot nnv-context, init-keyword: nnv-context:;
end;

define method make-command-line-server
    (#key real-context,
          banner :: false-or(<string>) = #f,
          input-stream :: <stream>,
          output-stream :: <stream>,
          echo-input? :: <boolean> = #f,
          profile-commands? :: <boolean> = #f)
 => (server :: <command-line-server>)
  let context = make(<nnv-context>,
                     banner: banner,
                     nnv-context: real-context);
  make(<command-line-server>,
       context:           context,
       input-stream:      input-stream,
       output-stream:     output-stream,
       echo-input?:       echo-input?,
       profile-commands?: profile-commands?)
end method make-command-line-server;

//--- Need a more modular way to do this (says the comment I copy&pasted...)
define constant $prompt-image-offset :: <integer> =  4;

define sealed method display-line
    (line :: <text-line>, mode :: <nnv-shell-mode>, window :: <basic-window>,
     x :: <integer>, y :: <integer>,
     #key start: _start = 0, end: _end = line-length(line), align-y = #"top") => ()
  let section = line-section(line);
  let image = case
		~shell-section?(section) =>
		  #f;
		line == section-start-line(section) =>
		  $prompt-arrow;
		line == section-output-line(section) =>
		  $values-arrow;
		otherwise =>
		  #f;
	      end;
  when (image & _start = 0)	// no icon on continuation lines
    let image-y = if (align-y == #"top") y else y - $prompt-image-height + 2 end;
    draw-image(window, standard-images(window, image), x, image-y + $prompt-image-offset)
  end;
  next-method(line, mode, window, x + $prompt-image-width, y,
	      start: _start, end: _end, align-y: align-y)
end method display-line;

define sealed method line-size
    (line :: <text-line>, mode :: <nnv-shell-mode>, window :: <basic-window>,
     #key start: _start, end: _end)
 => (width :: <integer>, height :: <integer>, baseline :: <integer>)
  ignore(_start, _end);
  let (width, height, baseline) = next-method();
  values(width + $prompt-image-width, height, baseline)
end method line-size;

define sealed method position->index
    (line :: <text-line>, mode :: <nnv-shell-mode>, window :: <basic-window>,
     x :: <integer>)
 => (index :: <integer>)
  let x = x - $prompt-image-width;
  if (x < 0) 0 else next-method(line, mode, window, x) end
end method position->index;

define sealed method index->position
    (line :: <text-line>, mode :: <nnv-shell-mode>, window :: <basic-window>,
     index :: <integer>)
 => (x :: <integer>)
  next-method(line, mode, window, index)
end method index->position;

define sealed method line-margin
    (line :: <text-line>, mode :: <nnv-shell-mode>, window :: <basic-window>)
 => (margin :: <integer>)
  $prompt-image-width
end method line-margin;



 











