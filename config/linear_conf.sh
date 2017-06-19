#!/bin/bash

MIN=-131072
MAX=131071
FACTOR=`dc ${1:-1.0} 0.5 mul p`
OFFSET=`dc ${2:-0.0} 65536 mul p`

./lut_conf3 -N 4096 -m $MIN -M $MAX -F $FACTOR -O $OFFSET -B 0x60500000
./lut_conf3 -N 4096 -m $MIN -M $MAX -F $FACTOR -O $OFFSET -B 0x60504000
./lut_conf3 -N 4096 -m $MIN -M $MAX -F $FACTOR -O $OFFSET -B 0x60508000
./lut_conf3 -N 4096 -m $MIN -M $MAX -F $FACTOR -O $OFFSET -B 0x6050C000
