#!/usr/bin/env python
# -*- coding: utf-8 -*-

class largeA(object):
    __nick__ = 'Alarge'
    name = 'largeA'
    def __init__(self):
        print 'largeA init invoked'


class bigA(object):
    def __init__(self):
        print 'bigA init invoked'

    def prints(self):
        print self.name
        print self.__nick__

class smalla(bigA, largeA):

    def show(self):
        print 'name', self.name
        print 'nick', self.__nick__

a = smalla()
a.show()
a.prints()
