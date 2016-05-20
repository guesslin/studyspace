#!/usr/bin/env python
# -*- coding: utf-8 -*-


class c1(object):
    def __init__(self):
        self.name = 'c1'

    def __del__(self):
        del self.name

    def call(self):
        print 'u r now calling {}'.format(self.name)


class c2(object):
    def __init__(self):
        self.name = 'c2'

    def __del__(self):
        del self.name

    def call(self):
        print 'u r now calling {}'.format(self.name)


if __name__ == '__main__':
    a = 'c1'
    tmp = a()
    tmp.call()
