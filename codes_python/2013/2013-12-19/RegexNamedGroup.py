#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re

string1 = '<person><name>Guesslin</name><age>27</age><\person>' '<person><name>abel</name><age>28</age><\person>' '<person><name>longest</name><age>26</age><\person>'

print
print string1
print

nr01 = r'((\<name\>(?P<name>[a-zA-Z]+)\<\/name\>)|(\<age\>(?P<age>[0-9]+)\<\/age\>))+'
nr02 = r'((\<age\>(?P<age>[0-9]+)\<\/age\>)|(\<name\>(?P<name>[a-zA-Z]+)\<\/name\>))+'

result01 = re.search(nr01, string1)
result02 = re.search(nr02, string1)


print nr01
print 'called by name'
print result01.group('name')
print result01.group('age')
print 'called by index\n'
print result01.groups()
print
for index in range(len(result01.groups()) + 1):
    print index, result01.group(index)
    print
print '========================================================='
print nr02
print 'called by name'
print result02.group('name')
print result02.group('age')
print 'called by index\n'
print result02.groups()
print
for index in range(len(result02.groups()) + 1):
    print index, result02.group(index)
    print

result03 = re.findall(nr01, string1)
print result03
