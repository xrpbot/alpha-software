----------------------------------------------------------------------------
--  reg_lut5.vhd
--	AXI3 Lite CFGLUT5 Interface
--	Version 1.0
--
--  Copyright (C) 2013 H.Poetzl
--
--	This program is free software: you can redistribute it and/or
--	modify it under the terms of the GNU General Public License
--	as published by the Free Software Foundation, either version
--	2 of the License, or (at your option) any later version.
----------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.ALL;

package lut5_pkg is

    type lut5_in_r is record
	I0	: std_logic;
	I1	: std_logic;
	I2	: std_logic;
	I3	: std_logic;
	I4	: std_logic;
    end record;

    type lut5_in_a is array (natural range <>) of
	lut5_in_r;

    type lut5_out_r is record
	O5	: std_logic;
	O6	: std_logic;
    end record;

    type lut5_out_a is array (natural range <>) of
	lut5_out_r;

end package;
