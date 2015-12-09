
create_clock -period 8.333 -name lvds_outclk -waveform {0.000 4.1667} [get_ports cmv_lvds_outclk*]

# set_input_delay -clock pll_lvds_clk -max  3.0 [get_ports cmv_lvds_data*]
# set_input_delay -clock pll_lvds_clk -max  3.0 [get_ports cmv_lvds_data*] -clock_fall -add_delay
# set_input_delay -clock pll_lvds_clk -min  2.0 [get_ports cmv_lvds_data*]
# set_input_delay -clock pll_lvds_clk -min  2.0 [get_ports cmv_lvds_data*] -clock_fall -add_delay

# set_input_delay -clock pll_lvds_clk -max  3.0 [get_ports cmv_lvds_ctrl*]
# set_input_delay -clock pll_lvds_clk -max  3.0 [get_ports cmv_lvds_ctrl*] -clock_fall -add_delay
# set_input_delay -clock pll_lvds_clk -min  2.0 [get_ports cmv_lvds_ctrl*]
# set_input_delay -clock pll_lvds_clk -min  2.0 [get_ports cmv_lvds_ctrl*] -clock_fall -add_delay

# set_input_delay -clock pll_lvds_clk -network_latency_included 3.333 [get_ports cmv_lvds_data*]
set_property PACKAGE_PIN E21 [get_ports cmv_clk_in]
set_property PACKAGE_PIN R7 [get_ports cmv_t_exp1]
set_property PACKAGE_PIN U7 [get_ports cmv_t_exp2]
set_property PACKAGE_PIN D21 [get_ports cmv_frame_req]

# set_input_delay -clock pll_lvds_clk -max -1.0 [get_ports cmv_lvds_data_p*]
# set_input_delay -clock pll_lvds_clk -min -1.5 [get_ports cmv_lvds_data_p*]
set_property PACKAGE_PIN T19 [get_ports cmv_sys_res_n]

# set_max_delay -from [get_ports cmv_lvds_data*] 0.5
set_property IOSTANDARD LVCMOS33 [get_ports cmv_t_*]
set_property IOSTANDARD LVCMOS25 [get_ports cmv_clk_in]
set_property IOSTANDARD LVCMOS25 [get_ports cmv_sys_res_n]
set_property IOSTANDARD LVCMOS25 [get_ports cmv_frame_req]


set_property PACKAGE_PIN C19 [get_ports cmv_lvds_outclk_n]
set_property PACKAGE_PIN D18 [get_ports cmv_lvds_outclk_p]

set_property PACKAGE_PIN L19 [get_ports cmv_lvds_clk_n]
set_property PACKAGE_PIN L18 [get_ports cmv_lvds_clk_p]

set_property PACKAGE_PIN A22 [get_ports cmv_lvds_ctrl_n]
set_property PACKAGE_PIN A21 [get_ports cmv_lvds_ctrl_p]

set_property PACKAGE_PIN E18 [get_ports {cmv_lvds_data_n[0]}]
set_property PACKAGE_PIN B15 [get_ports {cmv_lvds_data_n[1]}]
set_property PACKAGE_PIN A19 [get_ports {cmv_lvds_data_n[2]}]
set_property PACKAGE_PIN A17 [get_ports {cmv_lvds_data_n[3]}]
set_property PACKAGE_PIN D15 [get_ports {cmv_lvds_data_n[4]}]
set_property PACKAGE_PIN B20 [get_ports {cmv_lvds_data_n[5]}]
set_property PACKAGE_PIN J17 [get_ports {cmv_lvds_data_n[6]}]
set_property PACKAGE_PIN E20 [get_ports {cmv_lvds_data_n[7]}]
set_property PACKAGE_PIN G16 [get_ports {cmv_lvds_data_n[8]}]
set_property PACKAGE_PIN N18 [get_ports {cmv_lvds_data_n[9]}]
set_property PACKAGE_PIN M17 [get_ports {cmv_lvds_data_n[10]}]
set_property PACKAGE_PIN R21 [get_ports {cmv_lvds_data_n[11]}]
set_property PACKAGE_PIN M22 [get_ports {cmv_lvds_data_n[12]}]
set_property PACKAGE_PIN K18 [get_ports {cmv_lvds_data_n[13]}]
set_property PACKAGE_PIN T17 [get_ports {cmv_lvds_data_n[14]}]
set_property PACKAGE_PIN N20 [get_ports {cmv_lvds_data_n[15]}]

set_property PACKAGE_PIN F18 [get_ports {cmv_lvds_data_p[0]}]
set_property PACKAGE_PIN C15 [get_ports {cmv_lvds_data_p[1]}]
set_property PACKAGE_PIN A18 [get_ports {cmv_lvds_data_p[2]}]
set_property PACKAGE_PIN A16 [get_ports {cmv_lvds_data_p[3]}]
set_property PACKAGE_PIN E15 [get_ports {cmv_lvds_data_p[4]}]
set_property PACKAGE_PIN B19 [get_ports {cmv_lvds_data_p[5]}]
set_property PACKAGE_PIN J16 [get_ports {cmv_lvds_data_p[6]}]
set_property PACKAGE_PIN E19 [get_ports {cmv_lvds_data_p[7]}]
set_property PACKAGE_PIN G15 [get_ports {cmv_lvds_data_p[8]}]
set_property PACKAGE_PIN N17 [get_ports {cmv_lvds_data_p[9]}]
set_property PACKAGE_PIN L17 [get_ports {cmv_lvds_data_p[10]}]
set_property PACKAGE_PIN R20 [get_ports {cmv_lvds_data_p[11]}]
set_property PACKAGE_PIN M21 [get_ports {cmv_lvds_data_p[12]}]
set_property PACKAGE_PIN J18 [get_ports {cmv_lvds_data_p[13]}]
set_property PACKAGE_PIN T16 [get_ports {cmv_lvds_data_p[14]}]
set_property PACKAGE_PIN N19 [get_ports {cmv_lvds_data_p[15]}]

set_property IOSTANDARD LVDS_25 [get_ports cmv_lvds_*]

