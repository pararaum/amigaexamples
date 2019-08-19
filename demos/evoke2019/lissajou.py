#! /usr/bin/env python3

import math
import matplotlib.pyplot as plt

GRIDPTS = 900

xs = []
ys = []
for i in range(GRIDPTS):
    t = i * 2 * math.pi / GRIDPTS
    x = 140 + math.sin(2 * t) * 69
    y = 138 + math.sin(3 * t) * 75
    xs.append(x)
    ys.append(y)

plt.plot(xs, ys, 'go')
plt.show()

last = 0;
for i, (x, y) in enumerate(zip(xs, ys)):
    val = (int(y) << 8) | int(x)
    print("0x%04X, " % (val, ), end='')
    #print("0x%04X/*%04X*/, " % (val, val - last), end='')
    last = val
    if((i % 12) == 11):
        print('')
