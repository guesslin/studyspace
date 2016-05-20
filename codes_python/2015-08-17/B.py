#!/usr/bin/env python
# -*- coding: utf-8 -*-

from A import foo as f

_ = f


def foo(s):
    return "This is from B"
