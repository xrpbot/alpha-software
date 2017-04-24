----------------------------------------------------------------------------
--  ser_to_par.vhd (for cmv_io2)
--	N-Channel Deserializer Unit
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

package par_array_pkg is

    type par8_a is array (natural range <>) of
	std_logic_vector (7 downto 0);

    type par10_a is array (natural range <>) of
	std_logic_vector (9 downto 0);

    type par12_a is array (natural range <>) of
	std_logic_vector (11 downto 0);

    type par16_a is array (natural range <>) of
	std_logic_vector (15 downto 0);

end par_array_pkg;
