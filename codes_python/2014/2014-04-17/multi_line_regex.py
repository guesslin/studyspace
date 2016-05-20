#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import sys

test_str = sys.argv[1]

if re.search(r'(Sun|Mon|Tue|Wed|Thu|Fri|Sat), \d{1,2} '
             '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)'
             ' 20\d{2} 00:\d{2}:\d{2} \+0800', test_str):
    print 'YES, Match'
else:
    print 'NO, I can\'t find'
