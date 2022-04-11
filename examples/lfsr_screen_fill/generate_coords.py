#! /usr/bin/env python3

import math
import matplotlib.pyplot as plt

GRIDPTS = 900

xs = []
ys = []
for i in range(GRIDPTS):
    x = 138 + math.sin(float(2 * i) / GRIDPTS * 2 * math.pi) * 71 + math.cos(float(13 * i) / GRIDPTS * 2 * math.pi) * 13
    y = 128 + math.cos(float(2 * i) / GRIDPTS * 2 * math.pi) * 71 + math.sin(float(13 * i) / GRIDPTS * 2 * math.pi) * 13
    xs.append(x)
    ys.append(y)

plt.plot(xs, ys, 'go')
plt.show()

for i, (x, y) in enumerate(zip(xs, ys)):
    print("0x%04X, " % ((int(y) << 8) | int(x)), end='')
    if((i % 12) == 11):
        print('')
