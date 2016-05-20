#!/usr/bin/env python
# -*- coding: utf-8 -*-


filter001 = {'rule01': set(['a', 'b', 'c']), 'rule02': set(['c', 'e'])}
functions = ['a', 'c', 'e', 'b']
raw01 = {'name': 'a.exe', 'functions': set(functions)}
for i in filter001.keys():
    if filter001[i].issubset(raw01['functions']):
        print filter001[i], 'is subset of', raw01['functions']
