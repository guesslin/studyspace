#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import time
from functools import wraps


def timethis(func):
    @wraps(func)
    def func_wrap(*args, **kwargs):
        tstart = time.time()
        result = func(*args, **kwargs)
        tstop = time.time()
        print func.__name__, tstop - tstart
        return result
    return func_wrap


@timethis
def foo(n):
    s = 0
    for i in xrange(n):
        s += i
    return s


if __name__ == "__main__":
    print foo(int(sys.argv[1]))
