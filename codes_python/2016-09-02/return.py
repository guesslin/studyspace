#!/usr/bin/env python
# -*- coding: utf-8 -*-


def foo(i):
    s = 0

    for j in xrange(i):
        s += j  # dummy sum, 只是為了讓迴圈裡面有東西而已

    # 這個 j 的 lifetime 為什麼沒有結束？
    return j


if __name__ == '__main__':
    print foo(1399999)  # got 12 printed
