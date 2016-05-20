import time
import progressbar

bar = progressbar.ProgressBar(widgets=[
    ' [', progressbar.Timer(), '] ',
    progressbar.Bar(),
    ' (', progressbar.ETA(), ') ',
])
for i in bar(range(200)):
    time.sleep(0.1)
