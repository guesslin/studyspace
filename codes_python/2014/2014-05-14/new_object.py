#!/usr/bin/env python
# -*- coding: utf-8 -*-


class foo(object):
    def __init__(self):
        print 'foo'


class foo2(foo):
    def __init__(self):
        super(foo2, self).__init__()
        print 'foo2'

foo2()
