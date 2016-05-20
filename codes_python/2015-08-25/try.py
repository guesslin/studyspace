#!/usr/bin/env python
# -*- coding: utf-8 -*-


def foo(a):
    try:
        print a
        return 'from a'
    except Exception:
        print 'except'
        return 'from except'
    finally:
        print 'finally'
        return 'from finally'
        # if uncomment will overwrite return 'from except'


print 'start'
print foo('a')
print 'end'
