#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys


def title2number(s):
    table = dict(zip('ABCDEFGHIJKLMNOPQRSTUVWXYZ', [x for x in range(1, 27)]))
    result = 0
    s = s[::-1]
    for x in range(len(s)):
        result += table[s[x]]*(26**x)
    return result


if __name__ == '__main__':
    if len(sys.argv) == 2:
        print title2number(sys.argv[1])
    else:
        print 'nothing'
