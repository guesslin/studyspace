#!/usr/bin/env python
# -*- coding: utf-8 -*-

import time


def numeric_compare(x, y):
    return x - y


def numeric_compare2(x, y):
    return x > y


if __name__ == '__main__':
    a = [9, 11, 2, 8, 13, 0, -13, 21, 55]
    t = 10000000
    tStart = time.time()
    for i in xrange(t):
        sorted(a, cmp=numeric_compare)

    tEnd = time.time()
    print "x-y {} cost {} sec".format(t, tEnd - tStart)
    tStart = time.time()
    for i in xrange(t):
        sorted(a, cmp=numeric_compare2)

    tEnd = time.time()
    print "x>y {} cost {} sec".format(t, tEnd - tStart)

# Running result
# python cmp.py
# x-y 10000000 cost 47.1060450077 sec
# x>y 10000000 cost 24.1215779781 sec
