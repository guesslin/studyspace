from progressbar import *               # just a simple progress bar
import time


widgets = ['Test: ', Percentage(), ' ', Bar(marker="=",left='[',right=']', fill_left=True), ' ', ETA()] #see docs for other options

pbar = ProgressBar(widgets=widgets, maxval=20)
pbar.start()

for i in range(21):
    time.sleep(0.5)
    # here do something long at each iteration
    pbar.update(i) #this adds a little symbol at each iteration
pbar.finish()
