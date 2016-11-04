#!/usr/bin/env python
# -*- coding: utf-8 -*-


def find(xs, lo, hi):
    a, b = 0, 0
    n = len(xs)
    for i in range(n):
        while a != (n+1) and sum(xs[i:a]) < lo:
            a += 1
        while b != (n+1) and sum(xs[i:b]) <= hi:
            b += 1
        for j in range(a, b):
            print(xs[i:j])


if __name__ == '__main__':
    nums = [2, 5, 1, 1, 2, 2, 3, 4, 8, 2]
    find(nums, 3, 6)
