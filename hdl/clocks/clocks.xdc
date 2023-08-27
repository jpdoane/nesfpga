create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} [get_ports CLK_125MHZ]
create_generated_clock -name clk_hdmi -source [get_ports CLK_125MHZ] -divide_by 125 -multiply_by 27 [get_pins u_clocks/u_mmcm_hdmi/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name clk_hdmix5 -source [get_ports CLK_125MHZ] -divide_by 25 -multiply_by 27 [get_pins u_clocks/u_mmcm_hdmi/mmcm_adv_inst/CLKOUT1]
create_generated_clock -name clk_ppu8 -source [get_pins u_clocks/u_mmcm_hdmi/mmcm_adv_inst/CLKOUT0] -divide_by 39 -multiply_by 62 [get_pins u_clocks/u_mmcm_ppu_from_hdmi/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name clk_ppu -source [get_pins u_clocks/u_mmcm_ppu_from_hdmi/mmcm_adv_inst/CLKOUT0] -edges {1 2 17} [get_pins u_clocks/BUFGCE_ppu/O]
create_generated_clock -name clk_cpu -source [get_pins u_clocks/u_mmcm_ppu_from_hdmi/mmcm_adv_inst/CLKOUT0] -edges {1 2 49} [get_pins u_clocks/BUFGCE_cpu/O]

# create_generated_clock -name clk_ppu -source [get_pins u_clocks/u_mmcm_hdmi/mmcm_adv_inst/CLKOUT0] -divide_by 156 -multiply_by 31 [get_pins u_clocks/u_mmcm_ppu_from_hdmi/mmcm_adv_inst/CLKOUT0]
# create_generated_clock -name clk_cpu -source [get_pins u_clocks/u_mmcm_ppu_from_hdmi/mmcm_adv_inst/CLKOUT0] -edges {1 2 7} [get_pins u_clocks/BUFGCE_cpu/O]


# relax timing from ppu clock to hdmi clock
set_multicycle_path -setup -from [get_clocks clk_ppu8] -to [get_clocks clk_hdmi] 2

# relax timing between faster ppu8 clock and slow ppu/cpu
set_multicycle_path -setup -from [get_clocks clk_cpu] -to [get_clocks clk_ppu8] 3
set_multicycle_path -hold -end -from [get_clocks clk_cpu] -to [get_clocks clk_ppu8] 2
set_multicycle_path -setup -start -from [get_clocks clk_ppu8] -to [get_clocks clk_cpu] 3
set_multicycle_path -hold -from [get_clocks clk_ppu8] -to [get_clocks clk_ppu] 2

set_multicycle_path -setup -from [get_clocks clk_ppu] -to [get_clocks clk_ppu8] 3
set_multicycle_path -hold -end -from [get_clocks clk_ppu] -to [get_clocks clk_ppu8] 2
set_multicycle_path -setup -start -from [get_clocks clk_ppu8] -to [get_clocks clk_ppu] 3
set_multicycle_path -hold -from [get_clocks clk_ppu8] -to [get_clocks clk_ppu] 2

