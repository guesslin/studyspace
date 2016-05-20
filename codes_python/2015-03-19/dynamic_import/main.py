#!/usr/bin/env python
# -*- coding: utf-8 -*-

import pkgutil
from libs.base import Base


def dynamic_import():
    class_names = [n for _, n, _ in pkgutil.iter_modules(['modules'])]
    success = True
    for name in class_names:
        cls = 'modules.{}'.format(name)
        try:
            __import__(cls, globals(), locals(), ['dummy'], -1)
        except ImportError as e:
            success = False
    return success


if __name__ == '__main__':
    dynamic_import()
    for module in Base.__subclasses__():
        ins = module()
        ins.run()
