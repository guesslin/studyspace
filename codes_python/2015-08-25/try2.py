#!/usr/bin/env python
# -*- coding: utf-8 -*-


def demo1():
    try:
        raise RuntimeError("To Force Issue")
    except:
        return 1
    else:
        return 2
    finally:
        return 3


def demo2():
    try:
        try:
            RuntimeError
        except:
            return 1
        else:
            return 2
        finally:
            return 3
    except:
        print 4
    else:
        print 5
    finally:
        print 6


def demo3():
    try:
        print demo1()
    except:
        print 4
    else:
        print 5
    finally:
        print 6

if __name__ == "__main__":
    print "*** DEMO THREE ***"
    print demo3()
    print "******************"
