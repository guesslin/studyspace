#!/usr/bin/env python
# -*- coding: utf-8 -*-


class Base(object):
    name = 'Base'

    def __init__(self, user):
        self.user = user

    def __del__(self):
        del self.user


class Child(Base):
    pass

if __name__ == '__main__':
    C = Child('guesslin')
    print C.name
    print C.user
