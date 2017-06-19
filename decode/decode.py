#!/usr/bin/env python
from __future__ import print_function
from __future__ import division
import struct
from PIL import Image

f = open("test.dat", "r")

out_gray = Image.new("L", (2048, 1088))
out_data = out_gray.load()

x = 0
y = 0

# f.read(1024)

while True:
    data = f.read(24)
    if len(data) < 24:
        break
    
    data2 = struct.unpack("<24B", data)
    d = 0
    for i in range(0,24):
        d = d | (data2[i] << (i*8))
    
    for i in range(0, 16):
        pix = (d & 0xFFF)
        d >>= 12
        
        out_data[x,y] = pix
        x += 1
    
    if x >= 2048:
        x = 0
        y += 1
    
    if y >= 1088:
        break

f.close()

out = Image.new("RGB", (1024, 544))
rgb_data = out.load()

for y in range(0,544):
    for x in range(0,1024):
        rgb = (out_data[2*x, 2*y],
               (out_data[2*x+1, 2*y] + out_data[2*x, 2*y+1])//2,
               out_data[2*x+1, 2*y+1])
        rgb_data[x,y] = rgb

# out_gray.save("out.png")
out.save("out.png")
