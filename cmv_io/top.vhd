----------------------------------------------------------------------------
--  top.vhd
--	ZedBoard simple VHDL example
--	Version 1.0
--
--  Copyright (C) 2013 H.Poetzl
--
--	This program is free software: you can redistribute it and/or
--	modify it under the terms of the GNU General Public License
--	as published by the Free Software Foundation, either version
--	2 of the License, or (at your option) any later version.
--
--  Vivado 2013.2:
--    mkdir -p build.vivado
--    (cd build.vivado; vivado -mode tcl -source ../vivado.tcl)
--    (cd build.vivado; promgen -w -b -p bin -u 0 cmv_io.bit -data_width 32)
--
--  0xf8000900 rw	ps7::slcr::LVL_SHFTR_EN
--  devmem 0x600001FC 16 0x03AE ~ 42.0/43.0
--  devmem 0x600001FC 16 0x03AC ~ 41.0/42.5
--  devmem 0x600001FC 16 0x03A6 ~ 40.5/41.5
--  devmem 0x600001FC 16 0x0374 ~ 26.0/26.5
--  devmem 0x600001FC 16 0x0377 ~ 26.5/27.0
--			 0x0386 ~ 30.5/31.0

-- reg_oreg(0)	0000 0000 0000 0000  0000 0000 0000 0000
--		     ----    - ----       --------------
--		     MASK    R TRIG          PATTERN    

-- reg_oreg(1)	0000 0000 0000 0000  0000 0000 0000 0000
--		   - ----    - ----  --------- ---------
--		 OVERRIDE    C LRUD  OVERRIDE   SWITCH  

-- reg_oreg(2)	0000 0000 0000 0000  0000 0000 0000 0000
--		   - ----        --         -- ---------
--		   E CONV      DATA       C256  C64 RST 
--		     MASK      RST                      

-- reg_oreg(3)	0000 0000 0000 0000  0000 0000 0000 0000
--		---- ---- ---- ----  ---- ---- ---- ----
--		     ADDR FIFO ADDR       DATA      WRTR
--		     GEN  ADDR GEN        RST       ENAB
--		     AUTO RST  RST                      

----------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.ALL;

library unisim;
use unisim.VCOMPONENTS.all;

library unimacro;
use unimacro.VCOMPONENTS.all;

use work.axi3m_pkg.all;		-- AXI3 Master
use work.axi3ml_pkg.all;	-- AXI3 Lite Master

use work.axi3s_pkg.all;		-- AXI3 Slave Interface

use work.reduce_pkg.all;	-- Logic Reduction

use work.reg_array_pkg.ALL;
use work.val_array_pkg.ALL;


entity top is
    port (
	clk_100 : in std_logic;			-- input clock to FPGA
	--
	i2c0_sda : inout std_ulogic;
	i2c0_scl : inout std_ulogic;
	--
	-- i2c1_sda : inout std_ulogic;
	-- i2c1_scl : inout std_ulogic;
	--
	spi_en : out std_ulogic;
	spi_clk : out std_ulogic;
	spi_in : out std_ulogic;
	spi_out : in std_ulogic;
	--
	cmv_clk : out std_ulogic;
	cmv_t_exp1 : out std_ulogic;
	cmv_t_exp2 : out std_ulogic;
	cmv_frame_req : out std_ulogic;
	--
	cmv_lvds_clk_p : out std_logic;
	cmv_lvds_clk_n : out std_logic;
	--
	cmv_lvds_outclk_p : in std_logic;
	cmv_lvds_outclk_n : in std_logic;
	--
	cmv_lvds_data_p : in unsigned(15 downto 0);
	cmv_lvds_data_n : in unsigned(15 downto 0);
	--
	cmv_lvds_ctrl_p : in std_logic;
	cmv_lvds_ctrl_n : in std_logic;
	--
	pmod_jcm : out std_logic_vector(3 downto 0);
	pmod_jca : out std_logic_vector(3 downto 0);
	--
	pmod_jdm : out std_logic_vector(3 downto 0);
	pmod_jda : out std_logic_vector(3 downto 0);
	--
	btn_c : in std_logic;	-- Button: '1' is pressed
	btn_l : in std_logic;	-- Button: '1' is pressed
	btn_r : in std_logic;	-- Button: '1' is pressed
	btn_u : in std_logic;	-- Button: '1' is pressed
	btn_d : in std_logic;	-- Button: '1' is pressed
	--
	swi : in std_logic_vector(7 downto 0);
	led : out std_logic_vector(7 downto 0)
    );

end entity top;


architecture RTL of top is

    attribute KEEP_HIERARCHY : string;
    attribute KEEP_HIERARCHY of RTL : architecture is "TRUE";

    attribute DONT_TOUCH : string;
    attribute MARK_DEBUG : string;

    --------------------------------------------------------------------
    -- PS7 AXI Master Signals
    --------------------------------------------------------------------

    signal m_axi0_aclk : std_logic;
    signal m_axi0_areset_n : std_logic;

    signal m_axi0_ri : axi3m_read_in_r;
    signal m_axi0_ro : axi3m_read_out_r;
    signal m_axi0_wi : axi3m_write_in_r;
    signal m_axi0_wo : axi3m_write_out_r;

    signal m_axi0l_ri : axi3ml_read_in_r;
    signal m_axi0l_ro : axi3ml_read_out_r;
    signal m_axi0l_wi : axi3ml_write_in_r;
    signal m_axi0l_wo : axi3ml_write_out_r;

    signal m_axi00_aclk : std_logic;
    signal m_axi00_areset_n : std_logic;

    signal m_axi00_ri : axi3ml_read_in_r;
    signal m_axi00_ro : axi3ml_read_out_r;
    signal m_axi00_wi : axi3ml_write_in_r;
    signal m_axi00_wo : axi3ml_write_out_r;

    signal m_axi01_aclk : std_logic;
    signal m_axi01_areset_n : std_logic;

    signal m_axi01_ri : axi3ml_read_in_r;
    signal m_axi01_ro : axi3ml_read_out_r;
    signal m_axi01_wi : axi3ml_write_in_r;
    signal m_axi01_wo : axi3ml_write_out_r;

    signal m_axi010_aclk : std_logic;
    signal m_axi010_areset_n : std_logic;

    signal m_axi010_ri : axi3ml_read_in_r;
    signal m_axi010_ro : axi3ml_read_out_r;
    signal m_axi010_wi : axi3ml_write_in_r;
    signal m_axi010_wo : axi3ml_write_out_r;

    signal m_axi011_aclk : std_logic;
    signal m_axi011_areset_n : std_logic;

    signal m_axi011_ri : axi3ml_read_in_r;
    signal m_axi011_ro : axi3ml_read_out_r;
    signal m_axi011_wi : axi3ml_write_in_r;
    signal m_axi011_wo : axi3ml_write_out_r;

    --------------------------------------------------------------------
    -- PS7 AXI Slave Signals
    --------------------------------------------------------------------

    signal s_axi0_aclk : std_ulogic;
    signal s_axi0_areset_n : std_ulogic;

    signal s_axi0_wi : axi3s_write_in_r;
    signal s_axi0_wo : axi3s_write_out_r;

    signal s_axi1_aclk : std_ulogic;
    signal s_axi1_areset_n : std_ulogic;

    signal s_axi1_wi : axi3s_write_in_r;
    signal s_axi1_wo : axi3s_write_out_r;

    signal s_axi2_aclk : std_ulogic;
    signal s_axi2_areset_n : std_ulogic;

    signal s_axi2_wi : axi3s_write_in_r;
    signal s_axi2_wo : axi3s_write_out_r;

    signal s_axi3_aclk : std_ulogic;
    signal s_axi3_areset_n : std_ulogic;

    signal s_axi3_wi : axi3s_write_in_r;
    signal s_axi3_wo : axi3s_write_out_r;

    --------------------------------------------------------------------
    -- CMV SPI Signals
    --------------------------------------------------------------------

    signal cmv_spi_clk : std_ulogic;

    --------------------------------------------------------------------
    -- Register File Signals
    --------------------------------------------------------------------

    signal reg_oreg : reg_array(0 to 3);
    signal reg_ireg : reg_array(0 to 3);

    signal swi_mask : std_logic_vector(7 downto 0);
    signal swi_mval : std_logic_vector(7 downto 0);

    signal btn_mask : std_logic_vector(4 downto 0);
    signal btn_mval : std_logic_vector(4 downto 0);

    --------------------------------------------------------------------
    -- I2C0 Signals
    --------------------------------------------------------------------

    signal i2c0_sda_i : std_ulogic;
    signal i2c0_sda_o : std_ulogic;
    signal i2c0_sda_t : std_ulogic;
    signal i2c0_sda_t_n : std_ulogic;

    signal i2c0_scl_i : std_ulogic;
    signal i2c0_scl_o : std_ulogic;
    signal i2c0_scl_t : std_ulogic;
    signal i2c0_scl_t_n : std_ulogic;

    --------------------------------------------------------------------
    -- I2C1 Signals
    --------------------------------------------------------------------

    -- signal i2c1_sda_i : std_ulogic;
    -- signal i2c1_sda_o : std_ulogic;
    -- signal i2c1_sda_t : std_ulogic;
    -- signal i2c1_sda_t_n : std_ulogic;
 
    -- signal i2c1_scl_i : std_ulogic;
    -- signal i2c1_scl_o : std_ulogic;
    -- signal i2c1_scl_t : std_ulogic;
    -- signal i2c1_scl_t_n : std_ulogic;

    --------------------------------------------------------------------
    -- CMV PLL Signals
    --------------------------------------------------------------------

    signal cmv_pll : std_logic_vector(5 downto 0);
    signal cmv_pll_locked : std_ulogic;

    signal cmv_clk_300 : std_ulogic;
    signal cmv_clk_240 : std_ulogic;
    signal cmv_clk_200 : std_ulogic;
    signal cmv_clk_150 : std_ulogic;
    signal cmv_clk_30 : std_ulogic;
    signal cmv_clk_10 : std_ulogic;

    signal cmv_outclk : std_ulogic;

    --------------------------------------------------------------------
    -- LVDS MMCM Signals
    --------------------------------------------------------------------

    signal lvds_clk : std_logic_vector(5 downto 0);
    signal lvds_clk_locked : std_ulogic;

    signal lvds_clk_300 : std_ulogic;
    signal lvds_clk_150 : std_ulogic;
    signal lvds_clk_75 : std_ulogic;
    signal lvds_clk_50 : std_ulogic;
    signal lvds_clk_30 : std_ulogic;
    signal lvds_clk_10 : std_ulogic;

    --------------------------------------------------------------------
    -- CMV Serdes Signals
    --------------------------------------------------------------------

    constant CHANNELS : natural := 16;

    signal iserdes_clk : std_logic;
    signal iserdes_bitslip : std_logic_vector (CHANNELS downto 0);

    signal cmv_data_ser : unsigned (CHANNELS downto 0);

    type data_par_t is array (natural range <>) of
	std_logic_vector (11 downto 0);

    signal cmv_data_par : data_par_t (CHANNELS downto 0)
	:= (others => (others => '0'));
    signal cmv_push : std_logic_vector (CHANNELS downto 0);

    signal cmv_rst_sys : std_logic;

    signal cmv_pattern : std_logic_vector (11 downto 0);
    signal cmv_match : std_logic_vector (CHANNELS downto 0);
    signal cmv_fail : fail_cnt_array (CHANNELS downto 0);

    type data_t is array (natural range <>) of
	std_logic_vector (15 downto 0);

    signal cmv_data : data_t (CHANNELS - 1 downto 0)
	:= (others => (others => '0'));

    signal cmv_capture : std_logic;
    signal cmv_trigger : std_logic;

    --------------------------------------------------------------------
    -- LVDS IDELAY Signals
    --------------------------------------------------------------------

    signal idelay_val  : std_logic_vector (4 downto 0);
    signal idelay_oval : delay_val_array (CHANNELS downto 0);
    signal idelay_ld   : std_logic_vector (CHANNELS downto 0);

    signal idelay_valid : std_logic;
    signal idelay_clk  : std_logic;

    --------------------------------------------------------------------
    -- FIFO Signals
    --------------------------------------------------------------------

    function cwidth_f(
	data_width : in natural;
	fifo_size : in string )
	return natural is
	
	variable ret_v : natural;
    begin
	if(fifo_size = "18Kb") then
	    case data_width is
		when 0|1|2|3|4	=> ret_v := 12;
		when 5|6|7|8|9	=> ret_v := 11;
		when 10 to 18	=> ret_v := 10;
		when 19 to 36	=> ret_v := 9;
		when others	=> ret_v := 12;
	    end case;
	elsif(fifo_size = "36Kb") then
	    case data_width is
		when 0|1|2|3|4	=> ret_v := 13;
		when 5|6|7|8|9	=> ret_v := 12;
		when 10 to 18	=> ret_v := 11;
		when 19 to 36	=> ret_v := 10;
		when 37 to 72	=> ret_v := 9;
		when others	=> ret_v := 13;
	    end case;
	end if;
	return ret_v;
    end function;


    constant DATA_COUNT : natural := 2;
    constant DATA_WIDTH : natural := 64;
    constant DATA_CWIDTH : natural := cwidth_f(DATA_WIDTH, "36Kb");

    type fifo_data_t is array (natural range <>) of
	std_logic_vector (DATA_WIDTH - 1 downto 0);

    signal fifo_data_in : fifo_data_t(DATA_COUNT - 1 downto 0);
    signal fifo_data_out : fifo_data_t(DATA_COUNT - 1 downto 0);

    type fifo_dcount_t is array (natural range <>) of
	std_logic_vector (DATA_CWIDTH - 1 downto 0);

    signal fifo_data_rdcount : fifo_dcount_t(DATA_COUNT - 1 downto 0);
    signal fifo_data_wrcount : fifo_dcount_t(DATA_COUNT - 1 downto 0);

    signal fifo_data_reset : std_logic_vector(DATA_COUNT - 1 downto 0);

    signal fifo_data_wclk : std_logic;
    signal fifo_data_wen : std_logic_vector(DATA_COUNT - 1 downto 0);
    signal fifo_data_full : std_logic_vector(DATA_COUNT - 1 downto 0);
    signal fifo_data_wrerr : std_logic_vector(DATA_COUNT - 1 downto 0);

    signal fifo_data_rclk : std_logic_vector(DATA_COUNT - 1 downto 0);
    signal fifo_data_ren : std_logic_vector(DATA_COUNT - 1 downto 0);
    signal fifo_data_low : std_logic_vector(DATA_COUNT - 1 downto 0);
    signal fifo_data_empty : std_logic_vector(DATA_COUNT - 1 downto 0);
    signal fifo_data_rderr : std_logic_vector(DATA_COUNT - 1 downto 0);


    constant ADDR_COUNT : natural := 2;
    constant ADDR_WIDTH : natural := 32;
    constant ADDR_CWIDTH : natural := cwidth_f(ADDR_WIDTH, "18Kb");

    type fifo_addr_t is array (natural range <>) of
	std_logic_vector (ADDR_WIDTH - 1 downto 0);

    signal fifo_addr_in : fifo_addr_t(ADDR_COUNT - 1 downto 0);
    signal fifo_addr_out : fifo_addr_t(ADDR_COUNT - 1 downto 0);

    type fifo_acount_t is array (natural range <>) of
	std_logic_vector (ADDR_CWIDTH - 1 downto 0);

    signal fifo_addr_rdcount : fifo_acount_t(ADDR_COUNT - 1 downto 0);
    signal fifo_addr_wrcount : fifo_acount_t(ADDR_COUNT - 1 downto 0);

    signal fifo_addr_reset : std_logic_vector(ADDR_COUNT - 1 downto 0);

    signal fifo_addr_wclk : std_logic_vector(ADDR_COUNT - 1 downto 0);
    signal fifo_addr_wen : std_logic_vector(ADDR_COUNT - 1 downto 0);
    signal fifo_addr_full : std_logic_vector(ADDR_COUNT - 1 downto 0);
    signal fifo_addr_wrerr : std_logic_vector(ADDR_COUNT - 1 downto 0);

    signal fifo_addr_rclk : std_logic_vector(ADDR_COUNT - 1 downto 0);
    signal fifo_addr_ren : std_logic_vector(ADDR_COUNT - 1 downto 0);
    signal fifo_addr_empty : std_logic_vector(ADDR_COUNT - 1 downto 0);
    signal fifo_addr_rderr : std_logic_vector(ADDR_COUNT - 1 downto 0);

    --------------------------------------------------------------------
    -- Addr Gen Signals
    --------------------------------------------------------------------

    signal addr_gen_clk : std_logic_vector(ADDR_COUNT - 1 downto 0);
    signal addr_gen_reset : std_logic_vector(ADDR_COUNT - 1 downto 0);
    signal addr_gen_enable : std_logic_vector(ADDR_COUNT - 1 downto 0);
    signal addr_gen_auto : std_logic_vector(ADDR_COUNT - 1 downto 0);

    --------------------------------------------------------------------
    -- Writer Signals
    --------------------------------------------------------------------

    constant WRITER_COUNT : natural := 2;

    signal data_clk	: std_logic_vector(WRITER_COUNT - 1 downto 0);
    signal data_enable	: std_logic_vector(WRITER_COUNT - 1 downto 0);
    signal data_in	: fifo_data_t(WRITER_COUNT - 1 downto 0);
    signal data_empty	: std_logic_vector(WRITER_COUNT - 1 downto 0);

    signal data_reset	: std_logic_vector(WRITER_COUNT - 1 downto 0);

    signal addr_clk	: std_logic_vector(WRITER_COUNT - 1 downto 0);
    signal addr_enable	: std_logic_vector(WRITER_COUNT - 1 downto 0);
    signal addr_in	: fifo_addr_t(WRITER_COUNT - 1 downto 0);
    signal addr_empty	: std_logic_vector(WRITER_COUNT - 1 downto 0);

    signal addr_reset	: std_logic_vector(WRITER_COUNT - 1 downto 0);

    signal writer_enable : std_logic_vector(WRITER_COUNT - 1 downto 0);

    type writer_state_t is array (natural range <>) of
	std_logic_vector (7 downto 0);

    signal writer_state : writer_state_t(WRITER_COUNT - 1 downto 0);

    --------------------------------------------------------------------
    -- Combiner Signals
    --------------------------------------------------------------------

    constant COMB_COUNT : natural := 8;

    signal comb64_push : std_logic_vector(COMB_COUNT - 1 downto 0);
    signal comb64_reset : std_logic_vector(COMB_COUNT - 1 downto 0);

    type comb64_data_t is array (natural range <>) of
	std_logic_vector (63 downto 0);

    signal comb64_data : comb64_data_t (COMB_COUNT - 1 downto 0);

    signal comb256_push : std_logic_vector(WRITER_COUNT - 1 downto 0);
    signal comb256_reset : std_logic_vector(WRITER_COUNT - 1 downto 0);

    type comb256_data_t is array (natural range <>) of
	std_logic_vector (255 downto 0);

    signal comb256_data : comb256_data_t (WRITER_COUNT - 1 downto 0);

begin
    --------------------------------------------------------------------
    -- PS7 Interface
    --------------------------------------------------------------------

    ps7_stub_inst : entity work.ps7_stub
	port map (
	    i2c0_sda_i => i2c0_sda_i,
	    i2c0_sda_o => i2c0_sda_o,
	    i2c0_sda_t_n => i2c0_sda_t_n,
	    --
	    i2c0_scl_i => i2c0_scl_i,
	    i2c0_scl_o => i2c0_scl_o,
	    i2c0_scl_t_n => i2c0_scl_t_n,
	    --
	    -- i2c1_sda_i => i2c1_sda_i,
	    -- i2c1_sda_o => i2c1_sda_o,
	    -- i2c1_sda_t_n => i2c1_sda_t_n,
	    --
	    -- i2c1_scl_i => i2c1_scl_i,
	    -- i2c1_scl_o => i2c1_scl_o,
	    -- i2c1_scl_t_n => i2c1_scl_t_n,
	    --
	    m_axi0_aclk => m_axi0_aclk,
	    m_axi0_areset_n => m_axi0_areset_n,
	    --
	    m_axi0_arid => m_axi0_ro.arid,
	    m_axi0_araddr => m_axi0_ro.araddr,
	    m_axi0_arburst => m_axi0_ro.arburst,
	    m_axi0_arlen => m_axi0_ro.arlen,
	    m_axi0_arsize => m_axi0_ro.arsize,
	    m_axi0_arprot => m_axi0_ro.arprot,
	    m_axi0_arvalid => m_axi0_ro.arvalid,
	    m_axi0_arready => m_axi0_ri.arready,
	    --
	    m_axi0_rid => m_axi0_ri.rid,
	    m_axi0_rdata => m_axi0_ri.rdata,
	    m_axi0_rlast => m_axi0_ri.rlast,
	    m_axi0_rresp => m_axi0_ri.rresp,
	    m_axi0_rvalid => m_axi0_ri.rvalid,
	    m_axi0_rready => m_axi0_ro.rready,
	    --
	    m_axi0_awid => m_axi0_wo.awid,
	    m_axi0_awaddr => m_axi0_wo.awaddr,
	    m_axi0_awburst => m_axi0_wo.awburst,
	    m_axi0_awlen => m_axi0_wo.awlen,
	    m_axi0_awsize => m_axi0_wo.awsize,
	    m_axi0_awprot => m_axi0_wo.awprot,
	    m_axi0_awvalid => m_axi0_wo.awvalid,
	    m_axi0_awready => m_axi0_wi.wready,
	    --
	    m_axi0_wid => m_axi0_wo.wid,
	    m_axi0_wdata => m_axi0_wo.wdata,
	    m_axi0_wstrb => m_axi0_wo.wstrb,
	    m_axi0_wlast => m_axi0_wo.wlast,
	    m_axi0_wvalid => m_axi0_wo.wvalid,
	    m_axi0_wready => m_axi0_wi.wready,
	    --
	    m_axi0_bid => m_axi0_wi.bid,
	    m_axi0_bresp => m_axi0_wi.bresp,
	    m_axi0_bvalid => m_axi0_wi.bvalid,
	    m_axi0_bready => m_axi0_wo.bready,
	    --
	    s_axi0_aclk => s_axi0_aclk,
	    s_axi0_areset_n => s_axi0_areset_n,
	    --
	    s_axi0_awid => s_axi0_wi.awid,
	    s_axi0_awaddr => s_axi0_wi.awaddr,
	    s_axi0_awburst => s_axi0_wi.awburst,
	    s_axi0_awlen => s_axi0_wi.awlen,
	    s_axi0_awsize => s_axi0_wi.awsize,
	    s_axi0_awprot => s_axi0_wi.awprot,
	    s_axi0_awvalid => s_axi0_wi.awvalid,
	    s_axi0_awready => s_axi0_wo.awready,
	    s_axi0_wacount => s_axi0_wo.wacount,
	    --
	    s_axi0_wid => s_axi0_wi.wid,
	    s_axi0_wdata => s_axi0_wi.wdata,
	    s_axi0_wstrb => s_axi0_wi.wstrb,
	    s_axi0_wlast => s_axi0_wi.wlast,
	    s_axi0_wvalid => s_axi0_wi.wvalid,
	    s_axi0_wready => s_axi0_wo.wready,
	    s_axi0_wcount => s_axi0_wo.wcount,
	    --
	    s_axi0_bid => s_axi0_wo.bid,
	    s_axi0_bresp => s_axi0_wo.bresp,
	    s_axi0_bvalid => s_axi0_wo.bvalid,
	    s_axi0_bready => s_axi0_wi.bready,
	    --
	    s_axi1_aclk => s_axi1_aclk,
	    s_axi1_areset_n => s_axi1_areset_n,
	    --
	    s_axi1_awid => s_axi1_wi.awid,
	    s_axi1_awaddr => s_axi1_wi.awaddr,
	    s_axi1_awburst => s_axi1_wi.awburst,
	    s_axi1_awlen => s_axi1_wi.awlen,
	    s_axi1_awsize => s_axi1_wi.awsize,
	    s_axi1_awprot => s_axi1_wi.awprot,
	    s_axi1_awvalid => s_axi1_wi.awvalid,
	    s_axi1_awready => s_axi1_wo.awready,
	    s_axi1_wacount => s_axi1_wo.wacount,
	    --
	    s_axi1_wid => s_axi1_wi.wid,
	    s_axi1_wdata => s_axi1_wi.wdata,
	    s_axi1_wstrb => s_axi1_wi.wstrb,
	    s_axi1_wlast => s_axi1_wi.wlast,
	    s_axi1_wvalid => s_axi1_wi.wvalid,
	    s_axi1_wready => s_axi1_wo.wready,
	    s_axi1_wcount => s_axi1_wo.wcount,
	    --
	    s_axi1_bid => s_axi1_wo.bid,
	    s_axi1_bresp => s_axi1_wo.bresp,
	    s_axi1_bvalid => s_axi1_wo.bvalid,
	    s_axi1_bready => s_axi1_wi.bready,
	    --
	    s_axi2_aclk => s_axi2_aclk,
	    s_axi2_areset_n => s_axi2_areset_n,
	    --
	    s_axi2_awid => s_axi2_wi.awid,
	    s_axi2_awaddr => s_axi2_wi.awaddr,
	    s_axi2_awburst => s_axi2_wi.awburst,
	    s_axi2_awlen => s_axi2_wi.awlen,
	    s_axi2_awsize => s_axi2_wi.awsize,
	    s_axi2_awprot => s_axi2_wi.awprot,
	    s_axi2_awvalid => s_axi2_wi.awvalid,
	    s_axi2_awready => s_axi2_wo.awready,
	    s_axi2_wacount => s_axi2_wo.wacount,
	    --
	    s_axi2_wid => s_axi2_wi.wid,
	    s_axi2_wdata => s_axi2_wi.wdata,
	    s_axi2_wstrb => s_axi2_wi.wstrb,
	    s_axi2_wlast => s_axi2_wi.wlast,
	    s_axi2_wvalid => s_axi2_wi.wvalid,
	    s_axi2_wready => s_axi2_wo.wready,
	    s_axi2_wcount => s_axi2_wo.wcount,
	    --
	    s_axi2_bid => s_axi2_wo.bid,
	    s_axi2_bresp => s_axi2_wo.bresp,
	    s_axi2_bvalid => s_axi2_wo.bvalid,
	    s_axi2_bready => s_axi2_wi.bready,
	    --
	    s_axi3_aclk => s_axi3_aclk,
	    s_axi3_areset_n => s_axi3_areset_n,
	    --
	    s_axi3_awid => s_axi3_wi.awid,
	    s_axi3_awaddr => s_axi3_wi.awaddr,
	    s_axi3_awburst => s_axi3_wi.awburst,
	    s_axi3_awlen => s_axi3_wi.awlen,
	    s_axi3_awsize => s_axi3_wi.awsize,
	    s_axi3_awprot => s_axi3_wi.awprot,
	    s_axi3_awvalid => s_axi3_wi.awvalid,
	    s_axi3_awready => s_axi3_wo.awready,
	    s_axi3_wacount => s_axi3_wo.wacount,
	    --
	    s_axi3_wid => s_axi3_wi.wid,
	    s_axi3_wdata => s_axi3_wi.wdata,
	    s_axi3_wstrb => s_axi3_wi.wstrb,
	    s_axi3_wlast => s_axi3_wi.wlast,
	    s_axi3_wvalid => s_axi3_wi.wvalid,
	    s_axi3_wready => s_axi3_wo.wready,
	    s_axi3_wcount => s_axi3_wo.wcount,
	    --
	    s_axi3_bid => s_axi3_wo.bid,
	    s_axi3_bresp => s_axi3_wo.bresp,
	    s_axi3_bvalid => s_axi3_wo.bvalid,
	    s_axi3_bready => s_axi3_wi.bready );

    --------------------------------------------------------------------
    -- I2C bus #0
    --------------------------------------------------------------------

    i2c0_sda_t <= not i2c0_sda_t_n;

    IOBUF_sda_inst0 : IOBUF
	generic map (
	    IOSTANDARD => "LVCMOS33",
	    DRIVE => 4 )
	port map (
	    I => i2c0_sda_o, O => i2c0_sda_i,
	    T => i2c0_sda_t, IO => i2c0_sda );

    i2c0_scl_t <= not i2c0_scl_t_n;

    IOBUF_scl_inst0 : IOBUF
	generic map (
	    IOSTANDARD => "LVCMOS33",
	    DRIVE => 4 )
	port map (
	    I => i2c0_scl_o, O => i2c0_scl_i,
	    T => i2c0_scl_t, IO => i2c0_scl );

    --------------------------------------------------------------------
    -- I2C bus #1
    --------------------------------------------------------------------

    -- i2c1_sda_t <= not i2c1_sda_t_n;
   
    -- IOBUF_sda_inst1 : IOBUF
    -- generic map (
    --     IOSTANDARD => "LVCMOS33",
    --     DRIVE => 4 )
    -- port map (
    --     I => i2c1_sda_o, O => i2c1_sda_i,
    --     T => i2c1_sda_t, IO => i2c1_sda );
   
    -- i2c1_scl_t <= not i2c1_scl_t_n;
   
    -- IOBUF_scl_inst1 : IOBUF
	-- generic map (
	--     IOSTANDARD => "LVCMOS33",
	--     DRIVE => 4 )
	-- port map (
	--     I => i2c1_scl_o, O => i2c1_scl_i,
	--     T => i2c1_scl_t, IO => i2c1_scl );

    --------------------------------------------------------------------
    -- CMV PLL/LVDS MMCM
    --------------------------------------------------------------------

    lvds_pll_inst : entity work.lvds_pll
	port map (
	    ref_clk_in => clk_100,
	    --
	    pll_clk => cmv_pll,
	    pll_locked => cmv_pll_locked,
	    --
	    lvds_clk_in => cmv_outclk,
	    --
	    lvds_clk => lvds_clk,
	    lvds_locked => lvds_clk_locked );

    cmv_clk_300 <= cmv_pll(0);
    cmv_clk_240 <= cmv_pll(1);
    cmv_clk_200 <= cmv_pll(2);
    cmv_clk_150 <= cmv_pll(3);
    cmv_clk_30 <= cmv_pll(4);
    cmv_clk_10 <= cmv_pll(5);

    lvds_clk_300 <= lvds_clk(0);
    lvds_clk_150 <= lvds_clk(1);
    lvds_clk_75 <= lvds_clk(2);
    lvds_clk_50 <= lvds_clk(3);
    lvds_clk_30 <= lvds_clk(4);
    lvds_clk_10 <= lvds_clk(5);

    --------------------------------------------------------------------
    -- AXI3 Interconnect
    --------------------------------------------------------------------

    axi_lite_inst0 : entity work.axi_lite
	port map (
	    s_axi_aclk => m_axi0_aclk,
	    s_axi_areset_n => m_axi0_areset_n,

	    s_axi_ro => m_axi0_ri,
	    s_axi_ri => m_axi0_ro,
	    s_axi_wo => m_axi0_wi,
	    s_axi_wi => m_axi0_wo,

	    m_axi_ro => m_axi0l_ro,
	    m_axi_ri => m_axi0l_ri,
	    m_axi_wo => m_axi0l_wo,
	    m_axi_wi => m_axi0l_wi );

    axi_split_inst0 : entity work.axi_split
	generic map (
	    SPLIT_BIT => 16 )
	port map (
	    s_axi_aclk => m_axi0_aclk,
	    s_axi_areset_n => m_axi0_areset_n,
	    --
	    s_axi_ro => m_axi0l_ri,
	    s_axi_ri => m_axi0l_ro,
	    s_axi_wo => m_axi0l_wi,
	    s_axi_wi => m_axi0l_wo,
	    --
	    m_axi0_aclk => m_axi00_aclk,
	    m_axi0_areset_n => m_axi00_areset_n,
	    --
	    m_axi0_ri => m_axi00_ri,
	    m_axi0_ro => m_axi00_ro,
	    m_axi0_wi => m_axi00_wi,
	    m_axi0_wo => m_axi00_wo,
	    --
	    m_axi1_aclk => m_axi01_aclk,
	    m_axi1_areset_n => m_axi01_areset_n,
	    --
	    m_axi1_ri => m_axi01_ri,
	    m_axi1_ro => m_axi01_ro,
	    m_axi1_wi => m_axi01_wi,
	    m_axi1_wo => m_axi01_wo );

    axi_split_inst1 : entity work.axi_split
	generic map (
	    SPLIT_BIT => 12 )
	port map (
	    s_axi_aclk => m_axi0_aclk,
	    s_axi_areset_n => m_axi0_areset_n,
	    --
	    s_axi_ro => m_axi01_ri,
	    s_axi_ri => m_axi01_ro,
	    s_axi_wo => m_axi01_wi,
	    s_axi_wi => m_axi01_wo,
	    --
	    m_axi0_aclk => m_axi010_aclk,
	    m_axi0_areset_n => m_axi010_areset_n,
	    --
	    m_axi0_ri => m_axi010_ri,
	    m_axi0_ro => m_axi010_ro,
	    m_axi0_wi => m_axi010_wi,
	    m_axi0_wo => m_axi010_wo,
	    --
	    m_axi1_aclk => m_axi011_aclk,
	    m_axi1_areset_n => m_axi011_areset_n,
	    --
	    m_axi1_ri => m_axi011_ri,
	    m_axi1_ro => m_axi011_ro,
	    m_axi1_wi => m_axi011_wi,
	    m_axi1_wo => m_axi011_wo );

    --------------------------------------------------------------------
    -- CMV SPI Interface
    --------------------------------------------------------------------

    reg_spi_inst : entity work.reg_spi
	port map (
	    s_axi_aclk => m_axi00_aclk,
	    s_axi_areset_n => m_axi00_areset_n,
	    --
	    s_axi_ro => m_axi00_ri,
	    s_axi_ri => m_axi00_ro,
	    s_axi_wo => m_axi00_wi,
	    s_axi_wi => m_axi00_wo,
	    --
	    spi_bclk => cmv_spi_clk,
	    --
	    spi_clk => spi_clk,
	    spi_in => spi_in,
	    spi_out => spi_out,
	    spi_en => spi_en );

    -- m_axi0_aclk <= clk_100;
    -- m_axi0_aclk <= cmv_clk_150;
    m_axi0_aclk <= cmv_clk_30;

    cmv_spi_clk <= cmv_clk_10;

    --------------------------------------------------------------------
    -- Deser Register File
    --------------------------------------------------------------------

    reg_file_inst : entity work.reg_file
	generic map (
	    REG_BASE => 16#60000000#,
	    OREG_SIZE => 4,
	    IREG_SIZE => 4 )
	port map (
	    s_axi_aclk => m_axi010_aclk,
	    s_axi_areset_n => m_axi010_areset_n,
	    --
	    s_axi_ro => m_axi010_ri,
	    s_axi_ri => m_axi010_ro,
	    s_axi_wo => m_axi010_wi,
	    s_axi_wi => m_axi010_wo,
	    --
	    oreg => reg_oreg,
	    ireg => reg_ireg );

    cmv_pattern <= reg_oreg(0)(11 downto 0);

    swi_mask <= reg_oreg(1)(15 downto 8);
    swi_mval <= (swi and not swi_mask) or
	(reg_oreg(1)(7 downto 0) and swi_mask);

    btn_mask <= reg_oreg(1)(28 downto 24);
    btn_mval <= ((btn_c & btn_l & btn_r & btn_u & btn_d)
	and not btn_mask) or
	(reg_oreg(1)(20 downto 16) and btn_mask);

    --------------------------------------------------------------------
    -- Delay Control
    --------------------------------------------------------------------

    IDELAYCTRL_inst : IDELAYCTRL
	port map (
	    RDY => idelay_valid,	-- 1-bit output indicates validity of the REFCLK
	    REFCLK => cmv_clk_200,	-- 1-bit reference clock input
	    RST => cmv_rst_sys );	-- 1-bit reset input

    --------------------------------------------------------------------
    -- Delay Register File
    --------------------------------------------------------------------

    reg_delay_inst : entity work.reg_delay
	generic map (
	    REG_BASE => 16#60000000#,
	    CHANNELS => CHANNELS + 1 )
	port map (
	    s_axi_aclk => m_axi011_aclk,
	    s_axi_areset_n => m_axi011_areset_n,
	    --
	    s_axi_ro => m_axi011_ri,
	    s_axi_ri => m_axi011_ro,
	    s_axi_wo => m_axi011_wi,
	    s_axi_wi => m_axi011_wo,
	    --
	    delay_clk => idelay_clk,
	    delay_val => idelay_val,
	    delay_oval => idelay_oval,
	    delay_ld => idelay_ld,
	    --
	    match => cmv_match,
	    fail_cnt => cmv_fail,
	    bitslip => iserdes_bitslip );

    --------------------------------------------------------------------
    -- LVDS Input and Deserializer
    --------------------------------------------------------------------

    cmv_clk <= cmv_clk_30;

    cmv_frame_req <= btn_mval(4);
    cmv_t_exp1 <= btn_mval(3);
    cmv_t_exp2 <= btn_mval(2);

    OBUFDS_inst : OBUFDS
	generic map (
	    IOSTANDARD => "LVDS_25",
	    SLEW => "SLOW" )
	port map (
	    O => cmv_lvds_clk_p,
	    OB => cmv_lvds_clk_n,
	    I => '0' );

    IBUFDS_inst : IBUFDS
	generic map (
	    DIFF_TERM => TRUE,
	    IBUF_LOW_PWR => TRUE,
	    IOSTANDARD => "LVDS_25" )
	port map (
	    O => cmv_outclk,
	    I => cmv_lvds_outclk_p,
	    IB => cmv_lvds_outclk_n );

    GEN_LVDS: for I in CHANNELS downto 0 generate
    begin
	CTRL : if I = CHANNELS generate
	    IBUFDS_i : IBUFDS
		generic map (
		    DIFF_TERM => TRUE,
		    IBUF_LOW_PWR => TRUE,
		    IOSTANDARD => "LVDS_25" )
		port map (
		    O => cmv_data_ser(I),
		    I => cmv_lvds_ctrl_p,
		    IB => cmv_lvds_ctrl_n );

	end generate;

	DATA : if I < CHANNELS generate
	    IBUFDS_i : IBUFDS
		generic map (
		    DIFF_TERM => TRUE,
		    IBUF_LOW_PWR => TRUE,
		    IOSTANDARD => "LVDS_25" )
		port map (
		    O => cmv_data_ser(I),
		    I => cmv_lvds_data_p(I),
		    IB => cmv_lvds_data_n(I) );

	    cmv_data(I) <=
		cmv_data_par(CHANNELS)(3 downto 0) &
		cmv_data_par(I)(11 downto 0);

	end generate;

	cmv_deser_inst : entity work.cmv_deser
	    port map (
		serdes_clk	=> iserdes_clk,
		rst		=> cmv_rst_sys,
		--
		width		=> "00",
		--
		data_ser	=> cmv_data_ser(I),
		data_par	=> cmv_data_par(I),
		push		=> cmv_push(I),
		--
		pattern		=> cmv_pattern,
		match		=> cmv_match(I),
		fail_cnt	=> cmv_fail(I),
		--
		delay_clk	=> idelay_clk,
		delay_ce	=> '0',
		delay_inc	=> '0',
		delay_rst	=> '0',
		delay_ld	=> idelay_ld(I),
		delay_val	=> idelay_val,
		delay_oval	=> idelay_oval(I),
		--
		bitslip		=> iserdes_bitslip(I) );

    end generate;

    --------------------------------------------------------------------
    -- AXIHP Writer
    --------------------------------------------------------------------

    GEN_WRITER: for I in 1 downto 0 generate
    begin
	writer_enable(I) <= reg_oreg(3)(I);
	data_reset(I) <= reg_oreg(3)(8 + I);

	WRITER0 : if I = 0 generate
	    axihp_writer_inst0 : entity work.axihp_writer
		generic map (
		    DATA_WIDTH => 64,
		    DATA_COUNT => 16,
		    ADDR_MASK => x"00FFFFFF",
		    ADDR_DATA => x"1B000000" )
		port map (
		    m_axi_aclk => s_axi0_aclk,
		    m_axi_areset_n => s_axi0_areset_n,
		    enable => writer_enable(I),
		    --
		    m_axi_wo => s_axi0_wi,
		    m_axi_wi => s_axi0_wo,
		    --
		    data_clk => data_clk(I),
		    data_enable => data_enable(I),
		    data_in => data_in(I),
		    data_empty => data_empty(I),
		    --
		    addr_clk => addr_clk(I),
		    addr_enable => addr_enable(I),
		    addr_in => addr_in(I),
		    addr_empty => addr_empty(I),
		    --
		    writer_state => writer_state(I) );

	end generate;

	WRITER1 : if I = 1 generate
	    axihp_writer_inst2 : entity work.axihp_writer
		generic map (
		    DATA_WIDTH => 64,
		    DATA_COUNT => 16,
		    ADDR_MASK => x"00FFFFFF",
		    ADDR_DATA => x"1C000000" )
		port map (
		    m_axi_aclk => s_axi2_aclk,
		    m_axi_areset_n => s_axi2_areset_n,
		    enable => writer_enable(I),
		    --
		    m_axi_wo => s_axi2_wi,
		    m_axi_wi => s_axi2_wo,
		    --
		    data_clk => data_clk(I),
		    data_enable => data_enable(I),
		    data_in => data_in(I),
		    data_empty => data_empty(I),
		    --
		    addr_clk => addr_clk(I),
		    addr_enable => addr_enable(I),
		    addr_in => addr_in(I),
		    addr_empty => addr_empty(I),
		    --
		    writer_state => writer_state(I) );

	end generate;
    end generate;


    s_axi0_aclk <= cmv_clk_200;
    s_axi2_aclk <= cmv_clk_200;


    --------------------------------------------------------------------
    -- LED Status output
    --------------------------------------------------------------------

    led(0) <= cmv_pll_locked;
    led(1) <= lvds_clk_locked;
    led(2) <= idelay_valid;

    div_lvds_inst0 : entity work.async_div
	generic map (
	    STAGES => 28 )
	port map (
	    clk_in => cmv_clk_300,
	    clk_out => led(4) );

    div_lvds_inst1 : entity work.async_div
	generic map (
	    STAGES => 28 )
	port map (
	    clk_in => lvds_clk_150,
	    clk_out => led(5) );

    led(3) <= or_reduce (fifo_data_wrerr & fifo_data_rderr & 
			 fifo_addr_wrerr & fifo_addr_rderr);
    led(6) <= or_reduce (fifo_addr_empty);
    led(7) <= or_reduce (fifo_data_empty);

end RTL;
