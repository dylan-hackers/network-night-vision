module: priority-queue
author: Andreas Bogk <ich@andreas.org>
copyright: LGPL

// A priority queue uses the relation \< to order the entries

define class <priority-queue> (<deque>, <stretchy-collection>)
  constant slot heap :: <vector> = make(<stretchy-vector>);
  constant slot comparison-function :: <function>,
    init-value: \<, init-keyword: comparison-function:;
  virtual slot size :: <integer>, init-value: 0;
end class;

define open class <priority-queueable-mixin> (<object>)
  slot %index :: false-or(<integer>) = #f;
end;
define method size (pq :: <priority-queue>) => (size :: <object>)
  pq.heap.size;
end method size;

define method size-setter (size :: <integer>, pq :: <priority-queue>)
 => (new-size :: <integer>);
  size-setter(size, pq.heap);
end;

define method element (pq :: <priority-queue>, elt, #key default) => (ele)
  element(pq.heap, elt, default: default);
end;

//renamed to my-element-setter, otherwise would be added to generic
define method my-element-setter (new-value, pq :: <priority-queue>, key) => (nv)
  element-setter(new-value, pq.heap, key);
  new-value.%index := key;
end;

define method remove!(pq :: <priority-queue>, elt, #key test = \==, count = 0)
 => (pq :: <priority-queue>)
  let index = elt.%index;
  my-element-setter(pq[pq.size - 1], pq, index);
  pq.size := pq.size - 1;
  if (pq.size > 1 & pq.size > index)
    top-down(pq, index);
  end;
  pq;
end;

define method add!(pq :: <priority-queue>, value) => (pq :: <priority-queue>)
  if (value.%index)
    error("Timer can not be activated twice");
  end;
  let index :: <integer> = pq.size;

  pq.size := pq.size + 1;
  my-element-setter(value, pq, index);
  bottom-up(pq, index);
  pq;
end method add!;

define method bottom-up(pq :: <priority-queue>, index :: <integer>) => ();
  let bubble = pq[index];
  let super-index :: <integer> = ash(index, -1);

  while(index > 0 & pq.comparison-function(bubble, pq[super-index]))
    my-element-setter(pq[super-index], pq, index);
    index := super-index;
    super-index := ash(index + 1, -1) - 1;
  end while;

  my-element-setter(bubble, pq, index);
end method bottom-up;

define method pop(pq :: <priority-queue>) => (first-element :: <object>);
  let first-element = pq[0];

  my-element-setter(pq[pq.size - 1], pq, 0);
  pq.size := pq.size - 1;
  if(pq.size > 1)
    top-down(pq, 0);
  end if;
  first-element;
end method pop;
	
define method top-down(pq :: <priority-queue>, index :: <integer>) => ();
  let bubble = pq[index];
  let sub-index = ash(index + 1, 1) - 1;

  block(return)
    while(sub-index + 1 < pq.size)
      if(pq.comparison-function(pq[sub-index + 1], pq[sub-index]))
	sub-index := sub-index + 1;
      end if;
      if(pq.comparison-function(bubble, pq[sub-index]))
	return();
      end if;
      my-element-setter(pq[sub-index], pq, index);
      index := sub-index;
      sub-index := ash(index + 1, 1) - 1;
    end while;
    if(sub-index < pq.size & pq.comparison-function(pq[sub-index], bubble))
      my-element-setter(pq[sub-index], pq, index);
      index := sub-index;
    end if;
  end block;
  my-element-setter(bubble, pq, index);
end method top-down;
