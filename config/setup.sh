#!/bin/bash

DISP=${1:-DEEP}

. ./cmv.func
. ./hdmi.func

# devmem 0x80010018 32 0x00000

./gen_init.sh $DISP
./data_init.sh
./rmem_conf.sh
./wmem_conf.sh
./linear_conf.sh 1.3 0.2
./remap_conf.sh $DISP
./gamma_conf.sh 1

# ./mat4_conf.sh  1 0 0 0  0 1 0 0  0 0 1 0  0 0 0 1  0 0 0 0
./mat4_conf.sh 1 0 0 0  0 0.5 0.5 0  0 0.5 0.5 0  0 0 0 1  0 0 0 0

#for i in `seq 0 5`; do
#    ./adv7511_init.sh $DISP
#    sleep 0.5
#done

case $1 in
  SWIT)
    # scn_reg 28 0x31
    scn_reg 28 0x30
    ;;
  DEEP|1080p60|1080p50|1080p24)
    # scn_reg 28 0x30
    scn_reg 28 0x31
    ;;
  *)
    scn_reg 28 0x31
    ;;
esac
