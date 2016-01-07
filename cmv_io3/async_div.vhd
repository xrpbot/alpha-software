----------------------------------------------------------------------------
--  async_div.vhd
--	Asynchronous Binary Divider
--	Version 1.0
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
use IEEE.numeric_std.ALL;

library unisim;
use unisim.VCOMPONENTS.ALL;

use work.vivado_pkg.ALL;	-- Vivado Attributes


entity async_div is
    generic (
	STAGES	: natural := 8
    );
    port (
	clk_in	: in std_logic;		-- input clock
	--
	clk_out	: out std_logic		-- output clock
    );

end entity async_div;


architecture RTL of async_div is

    attribute KEEP_HIERARCHY of RTL : architecture is "TRUE";
    attribute ASYNC_REG of RTL : architecture is "TRUE";

    signal stage : std_logic_vector (STAGES - 1 downto 0);

    signal invq : std_logic_vector (STAGES - 1 downto 0);

begin

    GEN_STAGE : for N in 0 to STAGES - 1 generate
	INPUT : if N = 0 generate
	    FDCE_inst : FDCE
		port map (
		    Q => stage(N),
		    C => clk_in,
		    CE => '1',
		    CLR => '0',
		    D => invq(N));
	end generate;
	
	DEFAULT : if N > 0 generate
	    FDCE_inst : FDCE
		port map (
		    Q => stage(N),
		    C => stage(N - 1),
		    CE => '1',
		    CLR => '0',
		    D => invq(N));
	end generate;
    end generate;

    invq <= not stage;

    clk_out <= stage(STAGES - 1);

end RTL;
