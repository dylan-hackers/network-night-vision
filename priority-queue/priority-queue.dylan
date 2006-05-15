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

define method size (pq :: <priority-queue>) => (size :: <object>)
  pq.heap.size;
end method size;

define method size-setter (size :: <integer>, pq :: <priority-queue>)
 => (new-size :: <integer>);
  size-setter(size, pq.heap);
end;

define method remove!(pq :: <priority-queue>, my-element, #key test = \==, count = 0)
 => (pq :: <priority-queue>)
  let coll = pq.heap;
  let index = find-key(coll, curry(test, my-element), skip: count);
  coll[index] := coll[pq.size - 1];
  coll.size := coll.size - 1;
  if (coll.size > 0)
    top-down(pq, index);
  end;
  pq;
end;

define method add!(pq :: <priority-queue>, value) => (pq :: <priority-queue>)
  let index :: <integer> = pq.size;

  pq.size := pq.size + 1;
  pq.heap[index] := value;
  bottom-up(pq, index);
  pq;
end method add!;

define method bottom-up(pq :: <priority-queue>, index :: <integer>) => ();
  let bubble = pq.heap[index];
  let super-index :: <integer> = ash(index, -1);

  while(index > 0 & pq.comparison-function(pq.heap[super-index], bubble))
    pq.heap[index] := pq.heap[super-index];
    index := super-index;
    super-index := ash(index + 1, -1) - 1;
  end while;

  pq.heap[index] := bubble;
end method bottom-up;

define method pop(pq :: <priority-queue>) => (first-element :: <object>);
  let first-element = pq.heap[0];

  pq.heap[0] := pq.heap[pq.size - 1];
  pq.size := pq.size - 1;
  if(pq.size > 1)
    top-down(pq, 0);
  end if;
  first-element;
end method pop;
	
define method top-down(pq :: <priority-queue>, index :: <integer>) => ();
  let bubble = pq.heap[index];
  let sub-index = ash(index + 1, 1) - 1;

  block(return)
    while(sub-index + 1 < pq.size)
      if(pq.comparison-function(pq.heap[sub-index], pq.heap[sub-index + 1]))
	sub-index := sub-index + 1;
      end if;
      if(pq.comparison-function(pq.heap[sub-index], bubble))
	return();
      end if;
      pq.heap[index] := pq.heap[sub-index];
      index := sub-index;
      sub-index := ash(index + 1, 1) - 1;
    end while;
    if(sub-index < pq.size & pq.comparison-function(bubble, pq.heap[sub-index]))
      pq.heap[index] := pq.heap[sub-index];
      index := sub-index;
    end if;
  end block;
  pq.heap[index] := bubble;
end method top-down;
