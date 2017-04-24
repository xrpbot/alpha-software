#!/usr/bin/env python
from __future__ import print_function
from __future__ import division
import Image

def convert(l):
    i = 63
    x = 0
    
    for i in range(0, 64):
        if l[63-i] == '1':
            x += (1 << i)
        elif l[63-i] != '0':
            print("Warning: metavalue detected in output!")
    
    return x

f = open("output.dat", "r")

out = Image.new("L", (2048, 1088))
out_data = out.load()

x = 0
y = 0

while True:
    l0 = f.readline()
    l1 = f.readline()
    l2 = f.readline()
    
    if l2 == '':
        break
    
    d = convert(l0) | (convert(l1) << 64) | (convert(l2) << 128)
    
    for i in range(0, 16):
        pix = (d & 0xFF0) >> 2
        d >>= 12
        
        out_data[x,y] = pix
        x += 1
    
    if x >= 2048:
        x = 0
        y += 1

f.close()
out.save("out.png")
