#! /usr/bin/env python3

import math
import matplotlib.pyplot as plt

GRIDPTS = 900


R = 48.0
r = 8.0
d = 22.0
xs = []
ys = []
for i in range(GRIDPTS):
    t = i * 2 * math.pi / GRIDPTS
    x = 142 + (R + r) * math.cos(t) - d * math.cos((R + r) / r * t)
    y = 128 + (R + r) * math.sin(t) - d * math.sin((R + r) / r * t)
    xs.append(x)
    ys.append(y)

plt.plot(xs, ys, 'go')
plt.show()

last = 0;
deltas = set()
for i, (x, y) in enumerate(zip(xs, ys)):
    val = (int(y) << 8) | int(x)
    #print("0x%04X, " % (val, ), end='')
    print("0x%04X/*%04X*/, " % (val, val - last), end='')
    deltas.add(val - last)
    last = val
    if((i % 12) == 11):
        print('')
print("/*%s*/" % " ".join("%x" % i for i in sorted(deltas)))
