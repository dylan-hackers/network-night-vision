module: packetizer
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this distribution

define function find-frame-field (frame :: <container-frame>, search :: type-union(<container-frame>, <raw-frame>))
 => (res :: false-or(type-union(<frame-field>, <rep-frame-field>)))
  block(ret)
    for (ff in sorted-frame-fields(frame))
      if (ff.value == search)
        ret(ff)
      end;
      if (instance?(ff.value, <collection>))
        let framefield = choose-by(curry(\=, search),
                                   ff.value,
                                   ff.frame-field-list);
        if (framefield.size = 1) ret(framefield[0]) end;
      end;
    end;
    #f;
  end;
end;

define open generic compute-absolute-offset (a :: <object>, b :: <object>) => (res :: <integer>);
define method compute-absolute-offset (frame :: type-union(<container-frame>, <raw-frame>), relative-to) => (res :: <integer>)
  if (frame.parent & frame ~= relative-to)
    let ff = find-frame-field(frame.parent, frame);
    compute-absolute-offset(ff, relative-to);
  else
    0;
  end;
end;

define method compute-absolute-offset (ff :: <rep-frame-field>, relative-to)
 => (res :: <integer>)
  start-offset(ff) + compute-absolute-offset(ff.parent-frame-field, relative-to);
end;
define method compute-absolute-offset (frame-field :: <frame-field>, relative-to)
 => (res :: <integer>)
  start-offset(frame-field) + compute-absolute-offset(frame-field.frame, relative-to)
end;

define method compute-length (frame :: <header-frame>) => (res :: <integer>)
  start-offset(sorted-frame-fields(frame).last)
end;

define method compute-length (frame :: <frame>) => (res :: <integer>)
  frame-size(frame)
end;

define method compute-length (frame-field :: <position-mixin>) => (res :: <integer>)
  frame-field.length
end;

define method compute-length (frame-field :: <frame-field>) => (res :: <integer>)
  if (frame-field.field.field-name = #"payload")
    compute-length(frame-field.value)
  else
    frame-field.length;
  end
end;

define method find-frame-at-offset (frame :: <container-frame>, offset :: <integer>)
 => (result-frame)
  block(ret)
    for (ff in sorted-frame-fields(frame))
      if ((start-offset(ff) <= offset) & (end-offset(ff) >= offset))
        //format-out("looking in %s, offset %d\n", ff.field.field-name, offset - start-offset(ff));
        ret(find-frame-at-offset(ff.value, offset - start-offset(ff)));
      end;
    end;
  end;
end;

define method find-frame-at-offset (frame :: <collection>, offset :: <integer>)
  let start = 0;
  block(ret)
    for (ele in frame, i from 0)
      if ((start <= offset) & (frame-size(ele) >= offset))
        //format-out("looking in %d, offset %d\n", i, offset - start);
        ret(find-frame-at-offset(ele, offset - start));
      end;
      start := start + frame-size(ele);
    end;
  end;
end;

define method find-frame-at-offset (frame :: <leaf-frame>, offset :: <integer>)
  frame;
end;

