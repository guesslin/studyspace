#!/usr/bin/env python
# -*- coding: utf-8 -*-

class Top():
    pass

class Mid(Top):
    def __str__(self):
        return "I'm Mid"

class Bot(Mid):
    def __str__(self):
        return "I'm Bot"

class Mid2(Top):
    def __str__(self):
        return "I'm Mid2"

a = Top().__subclasshook__()
print a
