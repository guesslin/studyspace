#import console
#(width, height) = console.getTerminalSize()
#
#print "Your terminal's width is: %d" % width
import os
rows, columns = os.popen('stty size', 'r').read().split()
print "Your terminal's width is: %s, columns is: %s" % (rows, columns)
