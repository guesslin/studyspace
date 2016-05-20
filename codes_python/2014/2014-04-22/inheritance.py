#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re

re.DEBUG

class base(object):
    info = 'base'

    def show(self):
        print self.info


class inher(base):
    info = 'inher'

a = inher()
a.show()
