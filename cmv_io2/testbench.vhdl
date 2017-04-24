use std.textio.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;

use work.fifo_pkg.ALL;          -- FIFO Functions
use work.lut5_pkg.ALL;          -- LUT5 Record/Array
use work.reg_array_pkg.ALL;     -- Register Arrays
use work.par_array_pkg.ALL;     -- Parallel Data

entity testbench is
end testbench;

architecture behaviour of testbench is
    component pixel_remap
    generic (
        NB_LANES   : positive := 16 );
    port (
        clk        : in  std_logic;

        dv_par     : in  std_logic;     -- data valid according to clk
        ctrl_in    : in  std_logic_vector (12 - 1 downto 0);
        par_din    : in  par12_a (NB_LANES-1 downto 0);

        ctrl_out   : out std_logic_vector (12 - 1 downto 0);
        par_dout   : out par12_a (NB_LANES-1 downto 0) );
    end component;
    
    component fifo_chop
    port (
        par_clk		: in  std_logic;
        par_enable	: in  std_logic;
        par_data	: in  par12_a (31 downto 0);
        --
        par_ctrl	: in  std_logic_vector (11 downto 0);
        --
        fifo_clk	: out std_logic;
        fifo_enable	: out std_logic;
        fifo_data	: out std_logic_vector (63 downto 0);
        --
        fifo_ctrl	: out std_logic_vector (11 downto 0) );
    end component;
    
    --------------------------------------------------------------------
    -- TESTBENCH Signals
    --------------------------------------------------------------------

    file file_input: text;
    file file_output: text;

    shared variable ENDSIM: boolean;
    
    signal foo : std_logic_vector(11 downto 0);

    --------------------------------------------------------------------
    -- LVDS MMCM Signals
    --------------------------------------------------------------------

    signal lvds_pll_locked : std_ulogic;

    signal hdmi_clk : std_ulogic;
    signal lvds_clk : std_ulogic;
    signal word_clk : std_ulogic;

    signal cmv_outclk : std_ulogic;

    --------------------------------------------------------------------
    -- LVDS IDELAY Signals
    --------------------------------------------------------------------

    constant CHANNELS : natural := 16;

    signal idelay_valid : std_logic;

    signal idelay_in : std_logic_vector (CHANNELS + 1 downto 0);
    signal idelay_out : std_logic_vector (CHANNELS + 1 downto 0);

    --------------------------------------------------------------------
    -- CMV Serdes Signals
    --------------------------------------------------------------------

    alias serdes_clk : std_logic is lvds_clk;
    alias serdes_clkdiv : std_logic is word_clk;

    signal serdes_phase : std_logic;

    signal serdes_bitslip : std_logic_vector (CHANNELS + 1 downto 0);

    --------------------------------------------------------------------
    -- CMV Parallel Data Signals
    --------------------------------------------------------------------

    signal par_data : par12_a (CHANNELS downto 0);

    alias par_ctrl : std_logic_vector (11 downto 0)
        is par_data(CHANNELS);

    signal par_valid : std_logic;
    signal par_enable : std_logic;

    signal par_pattern : par12_a (CHANNELS downto 0);
    signal par_match : std_logic_vector (CHANNELS + 1 downto 0);
    signal par_mismatch : std_logic_vector (CHANNELS + 1 downto 0);

    --------------------------------------------------------------------
    -- Remapper Signals
    --------------------------------------------------------------------

    signal remap_ctrl : std_logic_vector (11 downto 0);
    signal remap_data : par12_a (CHANNELS-1 downto 0);
    
        --------------------------------------------------------------------
    -- Register File Signals
    --------------------------------------------------------------------

    constant OREG_SIZE : natural := 6;

    signal reg_oreg : reg32_a(0 to OREG_SIZE - 1);

    alias reg_pattern : std_logic_vector (11 downto 0)
        is reg_oreg(0)(11 downto 0);

    signal reg_mval : std_logic_vector (2 downto 0);
        -- is reg_oreg(0)(16 + 2 downto 16);

    signal reg_mask : std_logic_vector (2 downto 0);
        -- is reg_oreg(0)(24 + 2 downto 24);
    
    --------------------------------------------------------------------
    -- Writer Constants and Signals
    --------------------------------------------------------------------

    type waddr_a is array (natural range <>) of
        std_logic_vector (31 downto 0);

    constant WADDR_MASK : waddr_a(0 to 3) := 
        ( x"07FFFFFF", x"03FFFFFF", x"000FFFFF", x"000FFFFF" );
    constant WADDR_BASE : waddr_a(0 to 3) := 
        ( x"18000000", x"1C000000", x"1D000000", x"1E000000" );

    constant DATA_WIDTH : natural := 64;

    signal wdata_clk : std_logic;
    signal wdata_enable : std_logic;
    signal wdata_in : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal wdata_empty : std_logic;

    signal wdata_full : std_logic;

    constant ADDR_WIDTH : natural := 32;

    signal waddr_clk : std_logic;
    signal waddr_enable : std_logic;
    signal waddr_in : std_logic_vector (ADDR_WIDTH - 1 downto 0);
    signal waddr_empty : std_logic;

    signal waddr_match : std_logic;

    -- alias writer_clk : std_logic is cmv_axi_clk;

    signal writer_inactive : std_logic_vector (3 downto 0);
    signal writer_error : std_logic_vector (3 downto 0);

    signal writer_active : std_logic_vector (3 downto 0);
    signal writer_unconf : std_logic_vector (3 downto 0);

    --------------------------------------------------------------------
    -- Data FIFO Signals
    --------------------------------------------------------------------

    signal fifo_data_in : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal fifo_data_out : std_logic_vector (DATA_WIDTH - 1 downto 0);

    constant DATA_CWIDTH : natural := cwidth_f(DATA_WIDTH, "36Kb");

    signal fifo_data_rdcount : std_logic_vector (DATA_CWIDTH - 1 downto 0);
    signal fifo_data_wrcount : std_logic_vector (DATA_CWIDTH - 1 downto 0);

    signal fifo_data_wclk : std_logic;
    signal fifo_data_wen : std_logic;
    signal fifo_data_high : std_logic;
    signal fifo_data_full : std_logic;
    signal fifo_data_wrerr : std_logic;

    signal fifo_data_rclk : std_logic;
    signal fifo_data_ren : std_logic;
    signal fifo_data_low : std_logic;
    signal fifo_data_empty : std_logic;
    signal fifo_data_rderr : std_logic;

    signal fifo_data_rst : std_logic;
    signal fifo_data_rrdy : std_logic;
    signal fifo_data_wrdy : std_logic;

    signal fifo_ctrl : std_logic_vector (11 downto 0);

    signal match_en : std_logic;

    signal data_wen : std_logic;
    signal data_wen_d : std_logic;
    signal data_wen_dd : std_logic;

    signal data_in : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal data_in_d : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal data_in_dd : std_logic_vector (DATA_WIDTH - 1 downto 0);
    
    --------------------------------------------------------------------
    -- CFGLUT5 Signals
    --------------------------------------------------------------------

    -- alias lut_clk : std_logic is clk_100;

    signal lut_in : lut5_in_a (1 downto 0);
    signal lut_out : lut5_out_a (1 downto 0);

    alias lut_dval_in : std_logic is lut_in(0).I0;
    alias lut_lval_in : std_logic is lut_in(0).I1;
    alias lut_fval_in : std_logic is lut_in(0).I2;

    alias lut_fot_in : std_logic is lut_in(0).I3;

    alias lut_en_out : std_logic is lut_out(0).O5;


begin
    serdes_clk_gen : process
    begin
        if ENDSIM = false then
            serdes_clk <= '0';
            wait for 4.167 ns;
            serdes_clk <= '1';
            wait for 4.167 ns;
        else
            wait;
        end if;
    end process;
    
    serdes_clkdiv_gen : process
    begin
        if ENDSIM = false then
            serdes_clkdiv <= '0';
            wait for 20.833 ns;
            serdes_clkdiv <= '1';
            wait for 20.833 ns;
        else
            wait;
        end if;
    end process;

    par_data_gen: process
        variable in_line: line;
        variable load: std_logic_vector(9 downto 0);
        variable dummy: character;
    begin
        file_open(file_input, "input.dat", read_mode);
        
        while not endfile(file_input) loop
            readline(file_input, in_line);
            
            for I in 0 to 16 loop
                read(in_line, load);
                par_data(I) <= "00" & load;
            end loop;
            
            wait until serdes_clkdiv = '1';
            
            wait until serdes_clkdiv = '1';
        end loop;
        
        ENDSIM := true;
        
        file_close(file_input);
        wait;
    end process;
    
    fifo_data_handler: process
        variable out_line: line;
    begin
        file_open(file_output, "output.dat", write_mode);
        loop
            wait until fifo_data_wclk = '1';
            if fifo_data_wen = '1' then
                write(out_line, fifo_data_in);
                writeline(file_output, out_line);
            end if;
        end loop;
        file_close(file_output);
        wait;
    end process;
    
    serdes_bitslip <= ( others => '0' );
    
    reg_mask <= "001";
    reg_mval <= "001";
    
    foo <= par_data(16);
    
    fifo_data_wrdy <= '1';
    fifo_data_rrdy <= '1';
    
    -- begin stuff copied from top.vhd
    
    phase_proc : process (serdes_clkdiv)
        variable phase_v : std_logic := '0';
    begin
        serdes_phase <= phase_v;

        if rising_edge(serdes_clkdiv) then
            if serdes_bitslip(CHANNELS + 1) = '0' then
                phase_v := not phase_v;
            end if;
        end if;
    end process;

--    par_match_inst : entity work.par_match
--        generic map (
--            CHANNELS => CHANNELS + 1 )
--        port map (
--            par_clk	=> serdes_clkdiv,	-- in
--            par_data	=> par_data,		-- in
--            --
--            pattern	=> par_pattern,		-- in
--            --
--            match	=> par_match(CHANNELS downto 0),
--            mismatch	=> par_mismatch(CHANNELS downto 0) );

--    pattern_proc : process
--    begin
--        for I in CHANNELS - 1 downto 0 loop
--            par_pattern(I) <= reg_pattern;
--        end loop;

--        par_pattern(CHANNELS) <= x"080";
--    end process;

    --------------------------------------------------------------------
    -- Address Generator
    --------------------------------------------------------------------

--    addr_gen_inst : entity work.addr_gen
--        port map (
--            clk => waddr_clk,
--            reset => waddr_reset,
--            enable => waddr_enable,
--            --
--            addr_inc => waddr_inc,
--            addr_max => waddr_max,
--            --
--            addr => waddr_in,
--            match => waddr_match );

--    waddr_empty <= waddr_match or waddr_block;

    --------------------------------------------------------------------
    -- Data FIFO
    --------------------------------------------------------------------

    -- FIFO_data_inst : FIFO_DUALCLOCK_MACRO
	-- generic map (
	--     DEVICE => "7SERIES",
	--     DATA_WIDTH => DATA_WIDTH,
	--     ALMOST_FULL_OFFSET => x"020",
	--     ALMOST_EMPTY_OFFSET => x"020",
	--     FIFO_SIZE => "36Kb",
	--     FIRST_WORD_FALL_THROUGH => TRUE )
	-- port map (
	--     DI => fifo_data_in,
	--     WRCLK => fifo_data_wclk,
	--     WREN => fifo_data_wen,
	--     FULL => fifo_data_full,
	--     ALMOSTFULL => fifo_data_high,
	--     WRERR => fifo_data_wrerr,
	--     WRCOUNT => fifo_data_wrcount,
	--     --
	--     DO => fifo_data_out,
	--     RDCLK => fifo_data_rclk,
	--     RDEN => fifo_data_ren,
	--     EMPTY => fifo_data_empty,
	--     ALMOSTEMPTY => fifo_data_low,
	--     RDERR => fifo_data_rderr,
	--     RDCOUNT => fifo_data_rdcount,
	--     --
	--     RST => fifo_data_rst );

    -- fifo_reset_inst : entity work.fifo_reset
	-- port map (
	--     rclk => fifo_data_rclk,
	--     wclk => fifo_data_wclk,
	--     reset => fifo_data_reset,
	--     --
	--     fifo_rst => fifo_data_rst,
	--     fifo_rrdy => fifo_data_rrdy,
	--     fifo_wrdy => fifo_data_wrdy );


    pixel_remap_inst : entity work.pixel_remap
        generic map (
            NB_LANES => CHANNELS )
        port map (
            clk      => serdes_clkdiv,
            --
            dv_par   => par_valid,
            ctrl_in  => par_data(16),
            par_din  => par_data(15 downto 0),
            --
            ctrl_out => remap_ctrl,
            par_dout => remap_data(15 downto 0) );
     
--    remap_ctrl <= par_data(16);
--    remap_data(15 downto 0) <= par_data(15 downto 0);

    valid_proc : process (serdes_clkdiv)
    begin
        if rising_edge(serdes_clkdiv) then
            if serdes_phase = '1' then
                par_valid <= '1';
            else
                par_valid <= '0';
            end if;
        end if;
    end process;
    
    push_proc : process (serdes_clk)
        variable phase_d_v : std_logic;
    begin
        if rising_edge(serdes_clk) then
            if phase_d_v = '1' and serdes_phase = '0' then
                par_enable <= '1';
            else
                par_enable <= '0';
            end if;

            phase_d_v := serdes_phase;
        end if;
    end process;



    fifo_chop_inst : entity work.fifo_chop
        port map (
            par_clk => serdes_clk,
            par_enable => par_enable,
            par_data => remap_data(15 downto 0),
            --
            par_ctrl => remap_ctrl,
            --
            fifo_clk => fifo_data_wclk,
            fifo_enable => data_wen,
            fifo_data => data_in,
            --
            fifo_ctrl => fifo_ctrl );

        lut_dval_in <= fifo_ctrl(0);
        lut_lval_in <= fifo_ctrl(0);
        lut_fval_in <= fifo_ctrl(0);

    match_en <= '1'
        when (fifo_ctrl(2 downto 0) and reg_mask) = reg_mval
        else '0';

    data_filter_inst : entity work.data_filter
        port map (
            clk => fifo_data_wclk,
            enable => match_en,
            --
            en_in => data_wen,
            data_in => data_in,
            --
            en_out => data_wen_d,
            data_out => data_in_d );

    -- fifo_data_wclk <= iserdes_clk;
    fifo_data_wen <= data_wen_d when fifo_data_wrdy = '1' else '0';
    wdata_full <= fifo_data_full when fifo_data_wrdy = '1' else '1';
    fifo_data_in <= data_in_d;

    fifo_data_rclk <= wdata_clk;
    fifo_data_ren <= wdata_enable when fifo_data_rrdy = '1' else '0';
    wdata_empty <= fifo_data_low when fifo_data_rrdy = '1' else '1';
    wdata_in <= fifo_data_out;


    
    -- end stuff copied from top.vhd
end behaviour;
