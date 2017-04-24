----------------------------------------------------------------------------
--  reg_file.vhd
--	AXI Lite Register File
--	Version 1.1
--
--  Copyright (C) 2013 H.Poetzl
--
--	This program is free software: you can redistribute it and/or
--	modify it under the terms of the GNU General Public License
--	as published by the Free Software Foundation, either version
--	2 of the License, or (at your option) any later version.
--
----------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.ALL;

package reg_array_pkg is

    type reg64_a is array (natural range <>) of
	std_logic_vector (63 downto 0);

    type reg32_a is array (natural range <>) of
	std_logic_vector (31 downto 0);

    type reg16_a is array (natural range <>) of
	std_logic_vector (15 downto 0);

    type reg8_a is array (natural range <>) of
	std_logic_vector (7 downto 0);

end reg_array_pkg;
