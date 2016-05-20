#!/usr/bin/env python
# -*- coding: utf-8 -*-

try:
    print "in try"
    raise
except Exception:
    print "in Exception"
else:
    print "in else"
finally:
    print "in finally"
