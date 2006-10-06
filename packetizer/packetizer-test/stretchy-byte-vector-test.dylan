module: packetizer-test
Synopsis:  Test library for packetizer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define test byte-vector-subsequence-read ()
  let sbv = as(<stretchy-byte-vector-subsequence>, #(#x00, #x01, #x02, #x03));
  check-equal("Size of sbv is 4", 4, size(sbv));
  let sbv-sub = subsequence(sbv, start: 16, end: 32);
  check-equal("Size of subseq is 2", 2, size(sbv-sub));
  check-equal("content at element 0 is #x02", #x02, sbv-sub[0]);
  check-equal("content at element 1 is #x03", #x03, sbv-sub[1]);
  check-condition("-1 is out of bound", <out-of-bound-error>, sbv-sub[-1]);
  check-condition("2 is out of bound", <out-of-bound-error>, sbv-sub[2]);
  check-condition("3 is out of bound", <out-of-bound-error>, sbv-sub[3]);
end;

define test byte-vector-subsequence-modify ()
  let sbv = as(<stretchy-byte-vector-subsequence>, #(#x00, #x01, #x02, #x03));
  let sbv-sub = subsequence(sbv, start: 16, end: 32);
  check-equal("content at element 0 is #x02", #x02, sbv-sub[0]);
  check-equal("content at element 0 of sbv-sub is set to #x23", #x23, sbv-sub[0] := #x23);
  check-equal("content at element 0 is #x23", #x23, sbv-sub[0]);
  check-equal("content at element 2 of sbv is set to #x23", #x23, sbv[2]);
  check-condition("-1 is out of bound", <out-of-bound-error>, sbv-sub[-1] := #x42);
  check-condition("3 is out of bound", <out-of-bound-error>, sbv-sub[3] := #x56);
end;

define test byte-vector-subsequence-iteration ()
  let sbv = as(<stretchy-byte-vector-subsequence>, #(#x00, #x01, #x02, #x03));
  for (ele in sbv, i from 0)
    check-equal(format-to-string("Ele %d is correct", i), i, ele);
  end;
  check-equal("Map(-as) works", #(#x01, #x02, #x03, #x04), map-as(<list>, curry(\+, 1), sbv));
  let sbv-sub = subsequence(sbv, start: 16, end: 32);
  for (ele in sbv-sub, i from 0)
    check-equal(format-to-string("Ele %d is correct", i), i + 2, ele);
  end;
  check-equal("Map(-as) works", #(#x03, #x04), map-as(<list>, curry(\+, 1), sbv-sub));
end;

define test byte-vector-subsequence-iteration-modify ()
  let sbv = as(<stretchy-byte-vector-subsequence>, #(#x00, #x01, #x02, #x03));
  let sbv-sub = subsequence(sbv, start: 16, end: 32);
  replace-elements!(sbv-sub, method(x) #t end, curry(\*, 2));
  check-equal("Map(-as) works", #(#x04, #x06), map-as(<list>, method(x) x end, sbv-sub));
  check-equal("Map(-as) works", #(#x00, #x01, #x04, #x06), map-as(<list>, method(x) x end, sbv));
  replace-elements!(sbv, method(x) #t end, curry(\*, 2));
  check-equal("Map(-as) works", #(#x08, #x0c), map-as(<list>, method(x) x end, sbv-sub));
  check-equal("Map(-as) works", #(#x00, #x02, #x08, #x0c), map-as(<list>, method(x) x end, sbv));  
end;

define test byte-vector-subsequence-error-test ()
  let sbv = as(<stretchy-byte-vector-subsequence>, #(#x00, #x01, #x02, #x03));
  check-condition("negative offset", <out-of-bound-error>, subsequence(sbv, start: -1));
  let sbv-sub = subsequence(sbv, end: 32);
  check-condition("start beyond end", <out-of-bound-error>, subsequence(sbv-sub, start: 23 * 8));
  check-condition("end beyond end", <out-of-bound-error>, subsequence(sbv-sub, end: 23 * 8));
end;

define test byte-vector-subsequence-stretchy-test ()
  let sbv = as(<stretchy-byte-vector-subsequence>, #(#x00, #x01, #x02, #x03));
  check-equal("element 5 (index 4) to #x42", #x42, sbv[4] := #x42);
  check-equal("element 5 is #x42", #x42, sbv[4]);
  check-equal("size is 5", 5, sbv.size);
end;

define test byte-vector-subsequence-nested-test ()
  let sub = as(<stretchy-byte-vector-subsequence>,
    #(#x0, #x1, #x2, #x3, #x4, #x5, #x6, #x7, #x8, #x9, #xa, #xb, #xc, #xd, #xe, #xf, #x10, #x11));
  for (i from 0 below 8)
    sub := subsequence(sub, start: 8);
  end;
  check-instance?("nested subseq is byte-vector-subseq",
                  <stretchy-byte-vector-subsequence>,
                  sub);
  check-equal("nested subseq ele 0 is #x08", #x08, sub[0]);
  let sub2 = as(<stretchy-byte-vector-subsequence>,
    #(#x0, #x1, #x2, #x3, #x4, #x5, #x6, #x7, #x8, #x9, #xa, #xb, #xc, #xd, #xe, #xf, #x10, #x11));
  for (i from 0 below 2)
    sub2 := subsequence(sub2, start: 32);
  end;
  check-instance?("nested subseq is byte-vector-subseq",
                  <stretchy-byte-vector-subsequence>,
                  sub2);
  check-equal("nested subseq ele 0 is #x08", #x08, sub2[0]);
  let sub3 = as(<stretchy-byte-vector-subsequence>,
    #(#x0, #x1, #x2, #x3, #x4, #x5, #x6, #x7, #x8, #x9, #xa, #xb, #xc, #xd, #xe, #xf, #x10, #x11));
  for (i from 0 below 8)
    sub3 := subsequence(sub3, start: 8, end: 80 - (i * 8));
  end;
  check-instance?("nested subseq is byte-vector-subseq",
                  <stretchy-byte-vector-subsequence>,
                  sub3);
  check-equal("nested subseq ele 0 is #x08", #x08, sub3[0]);
  check-equal("size is 2", 2, sub3.size);
  check-condition("cant go after end", <out-of-bound-error>, subsequence(sub3, end: 32));
  check-condition("cant go after end with length", <out-of-bound-error>, subsequence(sub3, length: 24));
  check-condition("cant go negative with length", <out-of-bound-error>, subsequence(sub3, length: -24));
  check-condition("cant go negative with end", <out-of-bound-error>, subsequence(sub3, end: -24));
end;

define test byte-vector-subsequence-with-offset-read ()
  let sbv = as(<stretchy-byte-vector-subsequence>, #(#xff, #x00, #xf0, #x0f, #x00));
  let sub1 = subsequence(sbv, start: 1, end: 2);
  check-equal("size is 1", 1, sub1.size);
  check-equal("value is 1", 1, sub1[0]);
  check-condition("can't read element 1", <out-of-bound-error>, sub1[1]);
  check-condition("can't read element -1", <out-of-bound-error>, sub1[-1]);
  let sub2 = subsequence(sbv, start: 4, end: 8);
  check-equal("size is 1", 1, sub2.size);
  check-equal("value is 15", 15, sub2[0]);
  let sub2a = subsequence(sub2, start: 0, length: 0);
  check-equal("size is 0", 0, sub2a.size);
  check-condition("accessing ele 0 on empty", <out-of-bound-error>, sub2a[0]);
  let sub2b = subsequence(sub2, start: 0, end: 0);
  check-equal("size is 0", 0, sub2b.size);
  check-condition("accessing ele 0 on empty", <out-of-bound-error>, sub2b[0]);
  let sub3 = subsequence(sub2, start: 0, length: 2);
  check-equal("size is 1", 1, sub3.size);
  check-equal("value is 3", 3, sub3[0]);
  let sub3a = subsequence(sub2, start: 0, end: 2);
  check-equal("size is 1", 1, sub3a.size);
  check-equal("value is 3", 3, sub3a[0]);
  let sub4 = subsequence(sbv, start: 8, length: 12);
  check-equal("size is 2", 2, sub4.size);
  check-equal("value is 0", 0, sub4[0]);
  check-equal("value is 15", 15, sub4[1]);
  let sub5 = subsequence(sbv, start: 16, length: 23);
  check-equal("size is 3", 3, sub5.size);
  check-equal("value is 240", 240, sub5[0]);
  check-equal("value is 15", 15, sub5[1]);
  check-equal("value is 0", 0, sub5[2]);
  let sub6 = subsequence(sub5, start: 2, end: 10);
  check-equal("size is 1", 1, sub6.size);
  check-equal("value is 192", 192, sub6[0]);
  let sub7 = subsequence(sub5, start: 2, end: 11);
  check-equal("size is 2", 2, sub7.size);
  check-equal("value is 192", 192, sub7[0]);
  check-equal("value is 0", 0, sub7[1]);
end;

define test byte-vector-subsequence-with-offset-advanced ()
  let sbv = as(<stretchy-byte-vector-subsequence>, #(#x55, #x55, #xaa, #xaa));
  check-equal("value 0", #x55, sbv[0]);
  check-equal("value 1", #x55, sbv[1]);
  check-equal("value 2", #xaa, sbv[2]);
  check-equal("value 3", #xaa, sbv[3]);
  let sub1 = subsequence(sbv, start: 3, end: 7);
  check-equal("value of sub1", #xa, sub1[0]);
  let sub2 = subsequence(sub1, start: 1, end: 3);
  check-equal("value of sub2", #x1, sub2[0]);
  let sub3 = subsequence(sbv, start: 12, end: 20);
  check-equal("value of sub3", 90, sub3[0]);
  let sub4 = subsequence(sub3, start: 1, end: 5);
  check-equal("value of sub4", 11, sub4[0]);
  let sub5 = subsequence(sub3, start: 1, end: 6);
  check-equal("value of sub5", 22, sub5[0]);
  let sub6 = subsequence(sbv, start: 1, length: 24);
  check-equal("size of sub6", 3, size(sub6));
  check-equal("element 0 of sub6", #xaa, sub6[0]);
  check-equal("element 1 of sub6", 171, sub6[1]);
  check-equal("element 2 of sub6", #x55, sub6[2]);
  let sub7 = subsequence(sbv, start: 5, length: 24);
  check-equal("size of sub7", 3, size(sub7));
  check-equal("element 0 of sub7", #xaa, sub7[0]);
  check-equal("element 1 of sub7", 181, sub7[1]);
  check-equal("element 2 of sub7", #x55, sub7[2]);
end;

define test byte-vector-subsequence-with-offset-iteration ()
  let sbv = as(<stretchy-byte-vector-subsequence>, #(#x55, #x55, #x55));
  let sub = subsequence(sbv, start: 1);
  check-equal("size of sbv is 3", 3, size(sbv));
  check-equal("size of sub is 3", 3, size(sub));
  let count = 0;
  for (ele in sub, i from 1)
    if (i < sub.size)
      check-equal("value is #xaa", #xaa, ele);
    else
      check-equal("last value is 85", 85, ele);
    end;
    count := i;
  end;
  check-equal("count was 3", 3, count);
end;

define test byte-vector-subsequence-with-offset-modify ()
  let sbv = as(<stretchy-byte-vector-subsequence>, #(#xff));
  let sub = subsequence(sbv, start: 0, end: 4);
  check-equal("setting 0th element of sub", 0, sub[0] := 0);
  check-equal("0th element of sub", 0, sub[0]);
  check-equal("0th element of sbv", #x0f, sbv[0]);
  let sbv2 = as(<stretchy-byte-vector-subsequence>, #(#xf0));
  let sub2 = subsequence(sbv2, start: 4, end: 8);
  check-equal("setting 0th element of sub2", #xf, sub2[0] := #xf);
  check-equal("0th element of sub2", #xf, sub2[0]);
  check-equal("0th element of sbv2", #xff, sbv2[0]);
  let sbv3 = as(<stretchy-byte-vector-subsequence>, #(#xff, #xff, #xff, #xff, #xff));
  let sub3 = subsequence(sbv3, start: 4, length: 32);
  check-equal("setting 0th element of sub3", #x0, sub3[0] := #x0);
  check-equal("0th element of sub3", #x0, sub3[0]);
  check-equal("setting 1st element of sub3", #x0f, sub3[1] := #x0f);
  check-equal("1st element of sub3", #x0f, sub3[1]);
  check-equal("setting 2nd element of sub3", #xf0, sub3[2] := #xf0);
  check-equal("2nd element of sub3", #xf0, sub3[2]);
  check-equal("0th element of sbv3", #xf0, sbv3[0]);
  check-equal("1st element of sbv3", #x00, sbv3[1]);
  check-equal("2nd element of sbv3", #xff, sbv3[2]);
  check-equal("3rd element of sbv3", #x0f, sbv3[3]);
  check-equal("4th element of sbv3", #xff, sbv3[4]);
  let sbv4 = as(<stretchy-byte-vector-subsequence>, #(#x55, #x55, #x55));
  let sub4 = subsequence(sbv4, start: 6, end: 10);
  check-equal("sub4 size", 1, size(sub4));
  check-equal("0th element of sub4", #x5, sub4[0]);
  check-equal("setting 0th element", #xf, sub4[0] := #xf);
  check-equal("0th element of sub4", #xf, sub4[0]);
  check-equal("0th element of sbv4", #x57, sbv4[0]);
  check-equal("1st element of sbv4", #xd5, sbv4[1]);
end;

define test encode-integer-test ()
  let sbv = make(<stretchy-byte-vector-subsequence>);
  let sub1 = subsequence(sbv, start: 2);
  encode-integer(#x23, sub1, 6);
  check-equal("encode integer in bit vector", #x23, sbv[0]);
end;

define test encode-integer-test2 ()
  let sbv = make(<stretchy-byte-vector-subsequence>);
  let sub1 = subsequence(sbv, start: 6, length: 1);
  encode-integer(1, sub1, 1);
  check-equal("encode integer in bit vector", 2, sbv[0]);
end;
define suite stretchy-byte-vector-suite ()
  test byte-vector-subsequence-read;
  test byte-vector-subsequence-modify;
  test byte-vector-subsequence-iteration;
  test byte-vector-subsequence-iteration-modify;
  test byte-vector-subsequence-error-test;
  test byte-vector-subsequence-stretchy-test;
  test byte-vector-subsequence-nested-test;
  test byte-vector-subsequence-with-offset-read;
  test byte-vector-subsequence-with-offset-advanced;
  test byte-vector-subsequence-with-offset-iteration;
  test byte-vector-subsequence-with-offset-modify;
  test encode-integer-test;
  test encode-integer-test2;
end;

begin
  run-test-application(stretchy-byte-vector-suite, arguments: #("-debug"));
end;

