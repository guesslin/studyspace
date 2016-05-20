#!/usr/bin/env python

import random


def issorted(arr):
    tmp = arr[0]
    for i in range(1, len(arr)):
        if tmp > arr[i]:
            return False
        tmp = arr[i]
    return True

def main(size=3):
    arr = []
    for i in range(size):
        arr.append(random.randint(1,99))

    while not issorted(arr):
        print arr
        random.shuffle(arr)
    print arr

if __name__ == '__main__':
    main()
