create_clock -period 8.000 -name sys_clk -waveform {0.000 4.000} [get_ports CLK_125MHZ]


# create_generated_clock -add -name clk_hdmi -source [get_ports CLK_125MHZ] -master_clock sys_clk -divide_by 125 -multiply_by 27 $clk_hdmi_pin
# create_generated_clock -add -name clk_tdms -source [get_ports CLK_125MHZ] -master_clock sys_clk -divide_by 25 -multiply_by 27 $clk_tdms_pin
# create_generated_clock -add -name clk_nes -source $clk_hdmi_pin -master_clock clk_hdmi -divide_by 39 -multiply_by 62 $clk_nes_pin

create_generated_clock -name clk_hdmi [get_pins u_mmcm_hdmi/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name clk_tdms [get_pins u_mmcm_hdmi/mmcm_adv_inst/CLKOUT1]
create_generated_clock -name clk_nes [get_pins u_mmcm_nes_hdmi/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name clk_ppu -source [get_pins u_mmcm_nes_hdmi/mmcm_adv_inst/CLKOUT0] -edges {1 2 17} -add -master_clock clk_nes [get_pins u_nes/u_nes_clocks/BUFGCE_ppu/O]
create_generated_clock -name clk_cpu -source [get_pins u_mmcm_nes_hdmi/mmcm_adv_inst/CLKOUT0] -edges {1 2 49} -add -master_clock clk_nes [get_pins u_nes/u_nes_clocks/BUFGCE_cpu/O]

# relax timing from ppu clock to hdmi clock
set_multicycle_path -setup -from [get_clocks clk_ppu] -to [get_clocks clk_hdmi] 3
set_multicycle_path -hold -from [get_clocks clk_ppu] -to [get_clocks clk_hdmi] 2

# relax timing between faster ppu8 clock and slow ppu/cpu
set_multicycle_path -setup -from [get_clocks clk_cpu] -to [get_clocks clk_nes] 3
set_multicycle_path -hold -from [get_clocks clk_cpu] -to [get_clocks clk_nes] 2
set_multicycle_path -setup -from [get_clocks clk_cpu] -to [get_clocks clk_ppu] 3
set_multicycle_path -hold -from [get_clocks clk_cpu] -to [get_clocks clk_ppu] 2
# set_multicycle_path -setup -start -from [get_clocks clk_nes] -to [get_clocks clk_cpu] 3
# set_multicycle_path -hold -from [get_clocks clk_nes] -to [get_clocks clk_ppu] 2

set_multicycle_path -setup -from [get_clocks clk_ppu] -to [get_clocks clk_nes] 3
set_multicycle_path -hold -from [get_clocks clk_ppu] -to [get_clocks clk_nes] 2
# set_multicycle_path -setup -start -from [get_clocks clk_nes] -to [get_clocks clk_ppu] 3
# set_multicycle_path -hold -from [get_clocks clk_nes] -to [get_clocks clk_ppu] 2
