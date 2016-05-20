#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys



def main(fname):
    try:
        with open(fname, 'r') as fin:
            raw = fin.readlines()
    except IOError:
        print >>sys.stderr, "File doesn't exist!!"
    pool = {}
    for line in raw:
        terms = line.split()
        for term in terms:
            if term not in pool.keys():
                pool[term] = 1
            else:
                pool[term] += 1
    for key in sorted(pool.iterkeys()):
        space = '\t\t'
        if len(key) >= 8:
            space = '\t'
        print '%s%s%d' % (key, space, pool[key])

if __name__ == '__main__':
    try:
        main(sys.argv[1])
    except Exception, e:
        print >>sys.stderr, str(e), '\nNo filename Give'
        sys.exit(-1)
