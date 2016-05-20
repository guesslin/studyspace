#!/usr/bin/env python
# -*- coding: utf-8 -*-


class only(object):
    instance = None

    def __new__(cls, *args, **kwds):
        print '__new__ called'
        if only.instance is None:
            only.instance = object.__new__(cls)
        return only.instance

    def __init__(self, term='default'):
        if not hasattr(self, 'word'):
            self.word = term
        print '__init__ called'

    def show(self):
        print self.word

print only('guesslin')
a = only()
a.show()
print a
