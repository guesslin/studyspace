#!/usr/bin/env python
# -*- coding: utf-8 -*-


def foo2(kwargs):
    print kwargs['name']
    print kwargs['age']


def foo(**kwargs):
    print kwargs['number']
    print kwargs['name']
    print kwargs['age']
    if True and kwargs['number'] < 300:
        print 'Calling foo2'
        foo2(kwargs)


if __name__ == '__main__':
    foo(number=123, name='guesslin', age=28)
