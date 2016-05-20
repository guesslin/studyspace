#!/usr/bin/env python
# -*- coding: utf-8 -*-

import random


class puzzle(object):
    """
    self.broads = [[1, 2, 3],
                   [4, 5, 6],
                   [7, 8, 0]]
    final status of this eight puzzles game
    """

    def __init__(self, broads):
        self.broads = [broads[:3], broads[3:6], broads[6:]]

    def __eq__(self, other):
        if self.__class__ != other.__class__:
            return False
        return self.broads == other.broads

    def move(self, direction):
        if not self._check_before_move(direction):
            return False

        if direction == 'r':
            self._right()
        if direction == 'l':
            self._left()
        if direction == 'u':
            self._up()
        if direction == 'd':
            self._down()
        return True

    def show(self):
        for row in xrange(len(self.broads)):
            print ',\t'.join([str(x) for x in self.broads[row]])

    def solve(self):
        self.show()

    def _right(self):
        pass

    def _left(self):
        pass

    def _up(self):
        pass

    def _down(self):
        pass

    def _check_before_move(self, direction):
        pass

    def _swap(self, src, dst):
        tmp = self.broads[src[0]][src[1]]
        self.broads[src[0]][src[1]] = self.broads[dst[0]][dst[1]]
        self.broads[dst[0]][dst[1]] = tmp

    def _find_broad(self):
        for row in xrange(len(self.broads)):
            if 0 in self.broads[row]:
                self.borad_loc = [row, self.broads.index(0)]
                return row, self.broads.index(0)
        return None


if __name__ == '__main__':
    puzzles = [1, 2, 5, 4, 3, 6, 7, 8, 0]
    random.shuffle(puzzles)
    p = puzzle([x for x in puzzles])
    p.show()
    print
    p.solve()
