#!/usr/bin/env python
# -*- coding: utf-8 -*-

import profile


def foo1(num):
    tmp = 0
    for i in xrange(num):
        tmp = tmp + i
    print tmp


def foo2(num):
    tmp = 0
    for i in range(num):
        tmp = tmp + i
    print tmp


if __name__ == '__main__':
    print 'start up section'
    profile.run('foo1(10000000)')
    profile.run('foo2(10000000)')
