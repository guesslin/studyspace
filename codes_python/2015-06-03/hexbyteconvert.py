#!/usr/bin/env python
# -*- coding: utf-8 -*-


def hex2byte(hexwords):
    if len(hexwords) % 2:
        raise Exception("Wrong Length")
    print hexwords


if __name__ == '__main__':
    import sys
    hex2byte(sys.argv[1])
