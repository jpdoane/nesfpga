create_clock -period 8.000 -name sys_clk -waveform {0.000 4.000} [get_ports CLK_125MHZ]

create_generated_clock -name clk_hdmi [get_pins -hierarchical u_mmcm_hdmi/CLKOUT0]
create_generated_clock -name clk_tdms [get_pins -hierarchical u_mmcm_hdmi/CLKOUT1]
create_generated_clock -name clk_nes [get_pins -hierarchical mmcm_nes_from_hdmi/CLKOUT0]
create_generated_clock -name clk_ppu -source [get_pins -hierarchical mmcm_nes_from_hdmi/CLKOUT0] -edges {1 2 17} -add -master_clock clk_nes [get_pins -hierarchical BUFGCE_ppu/O]
create_generated_clock -name clk_cpu -source [get_pins -hierarchical mmcm_nes_from_hdmi/CLKOUT0] -edges {1 2 49} -add -master_clock clk_nes [get_pins -hierarchical BUFGCE_cpu/O]

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
