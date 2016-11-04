#!/usr/bin/env python
# -*- coding: utf-8 -*-


def pas(nums):
    p = 1
    n = len(nums)
    output = []
    for i in range(0, n):
        output.append(p)
        p = p * nums[i]
        print p

    print output

    p = 1
    for i in range(n-1, -1, -1):
        output[i] = output[i] * p
        p = p * nums[i]
        print p

    return output


if __name__ == '__main__':
    nums = [1, 2, 3, 4]
    s = pas(nums)
    print s
