#!/bin/sh

cd "${0%/*}"		# change into script dir

. ./cmv.func

cmv_reg 111  #Bit_mode 10 bit
cmv_reg 112 0 #ADC_res 10bit
cmv_reg 117 8 #10bit pll load
cmv_reg 116 25 #30-20 MHz
cmv_reg 114 0 #30-20 MHz

cmv_reg 41 0 # Inte_sync | Exp_dual | Exp_ext
cmv_reg 74 0 # I_lvds_rec
cmv_reg 77 0 # Col_calib | ADC_calib
cmv_reg 84 4 # l_col
cmv_reg 85 1 # l_col_prech
cmv_reg 87 12 # l_amp
cmv_reg 88 64 # Vtf_l1
cmv_reg 91 64 # Vres_low
cmv_reg 94 101 # V_precj
cmv_reg 95 106 # V_ref
cmv_reg 98 109 # V_ramp1
cmv_reg 99 109 # V_ramp2
cmv_reg 102 1 # PGA
cmv_reg 103 49 # ADC_GAIN
cmv_reg 118 1 # Dummy
cmv_reg 123 98 # V_blacksun

#cmv_reg 113 0 #PLL enable
#cmv_reg 115 1 #PLL bypass
cmv_reg 80 255 # Enable All LVDS pins
cmv_reg 81 255 # Enable All LVDS pins
cmv_reg 82 3 # Disable LVDS input pin
#cmv_reg 74 8 # LVDS current

cmv_reg 113 1 #PLL enable
cmv_reg 115 0 #use internal pll
cmv_reg 74 0 #LVDS current off
#
#cmv_reg 116 217 #30-20 MHz
#cmv_reg 114 0 #30-20 MHz

