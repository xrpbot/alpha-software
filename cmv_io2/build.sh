#!/bin/bash
ghdl -a --ieee=synopsys vivado_pkg.vhd
ghdl -a --ieee=synopsys ser_to_par.vhd
ghdl -a --ieee=synopsys reg_lut5.vhd
ghdl -a --ieee=synopsys reg_file.vhd
ghdl -a --ieee=synopsys data_filter.vhd
ghdl -a --ieee=synopsys ram_sdp_reg.vhd
ghdl -a --ieee=synopsys pixel_remap.vhd
ghdl -a --ieee=synopsys fifo_pkg.vhd
ghdl -a --ieee=synopsys fifo_chop.vhd
ghdl -a --ieee=synopsys testbench.vhdl
ghdl -e --ieee=synopsys testbench
