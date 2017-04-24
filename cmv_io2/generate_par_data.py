#!/usr/bin/env python
from __future__ import print_function
from __future__ import division
import Image

def bitstring(x, n):
    return ''.join([ '1' if x & (1<<i) else '0' for i in range(n-1, -1, -1) ])

img = Image.open("test.png")

# Image size must match sensor
assert(img.size == (2048, 1088))

data = img.load()

# Idle before frame
for i in range(0, 42):
    for ch in range(0, 16):
        print(bitstring(0, 10), end=' ')
    print(bitstring(0x200, 10))

for row in range(0, 1088):
    for pix in range(0, 128):
        bayer = (row % 2) + (pix % 2)
        for ch in range(0, 16):
            print(bitstring(4 * data[pix + 128*ch, row][bayer], 10), end=' ')
        print(bitstring(0x207, 10))
    
    # Idle after line
    if row != 1087:
        for ch in range(0, 16):
            print(bitstring(0, 10), end=' ')
        print(bitstring(0x204, 10))

# Idle after frame
for i in range(0, 42):
    for ch in range(0, 16):
        print(bitstring(0, 10), end=' ')
    print(bitstring(0x200, 10))
