#!/usr/bin/env python
# -*- coding: utf-8 -*-

import random
import time
# from multiprocessing import Process as pc
# from multiprocessing import Pipe as pp
from progressbar import Bar
from progressbar import RotatingMarker
from progressbar import Counter
from progressbar import ProgressBar
from progressbar import ETA
from progressbar import Percentage


toolbar_width = random.randint(30, 50)
filename = ''
widgets = ['Title:', Percentage(), RotatingMarker(), ' ',
           Bar(marker='>', left='[', right=']', fill='#'),
           ' ', ETA(), ' ', Counter(), '|', str(toolbar_width), ' ',
           '---']

pbar = ProgressBar(widgets=widgets, maxval=toolbar_width)
filename_list = ['aaa', 'bbbb', 'ccc', 'ddd', 'eee']
pbar.start()
for i in range(0, toolbar_width+1, 1):
    time.sleep(0.1)
    widgets[12] = '{:4s}'.format(filename_list[i % 5])
    pbar.update(i)

pbar.finish()
print
