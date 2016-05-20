import time
import progressbar


def myrange(n):
    for i in range(n):
        yield i


bar = progressbar.ProgressBar()
for i in bar(range(100)):
    time.sleep(0.1)
