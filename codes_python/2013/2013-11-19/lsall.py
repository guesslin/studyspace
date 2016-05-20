#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys


def lsall(dirname):
    cur = os.listdir(os.path.join(dirname))
    dirlist = []
    for item in cur:
        if os.path.isdir(os.path.join(dirname, item)):
            dirlist.append(os.path.join(dirname, item))
        print os.path.join(dirname, item)
    for diritem in dirlist:
        lsall(diritem)


if __name__ == '__main__':
    try:
        lsall(sys.argv[1])
    except IndexError, e:
        print str(e)
        print 'No dir gived!!'
