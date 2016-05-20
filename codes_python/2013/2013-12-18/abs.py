#!/usr/bin/env python
# -*- coding: utf-8 -*-

class top(object):
    def run(self):
        raise NotImplementedError

class top2(object):
    pass

class mid(top):
    def run(self):
        print "running"

class mid2(top):
    pass

class mid3(top2):
    pass

for sc in top.__subclasses__():
    try:
        tmp = sc()
        tmp.run()
    except NotImplementedError, e:
        print 'NotImplementedError', str(e)
    """
    Prints one running and Raise one NotImplementedError
    """

for sc in top2.__subclasses__():
    try:
        tmp = sc()
        tmp.run()
    except Exception, e:
        print str(e)
