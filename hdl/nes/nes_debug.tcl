
create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list u_clocks/u_mmcm_ppu_from_hdmi/clk_nes]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {u_nes/u_apu/u_core_6502/ip[0]} {u_nes/u_apu/u_core_6502/ip[1]} {u_nes/u_apu/u_core_6502/ip[2]} {u_nes/u_apu/u_core_6502/ip[3]} {u_nes/u_apu/u_core_6502/ip[4]} {u_nes/u_apu/u_core_6502/ip[5]} {u_nes/u_apu/u_core_6502/ip[6]} {u_nes/u_apu/u_core_6502/ip[7]} {u_nes/u_apu/u_core_6502/ip[8]} {u_nes/u_apu/u_core_6502/ip[9]} {u_nes/u_apu/u_core_6502/ip[10]} {u_nes/u_apu/u_core_6502/ip[11]} {u_nes/u_apu/u_core_6502/ip[12]} {u_nes/u_apu/u_core_6502/ip[13]} {u_nes/u_apu/u_core_6502/ip[14]} {u_nes/u_apu/u_core_6502/ip[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 32 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {u_nes/u_apu/u_core_6502/cpu_cycle[0]} {u_nes/u_apu/u_core_6502/cpu_cycle[1]} {u_nes/u_apu/u_core_6502/cpu_cycle[2]} {u_nes/u_apu/u_core_6502/cpu_cycle[3]} {u_nes/u_apu/u_core_6502/cpu_cycle[4]} {u_nes/u_apu/u_core_6502/cpu_cycle[5]} {u_nes/u_apu/u_core_6502/cpu_cycle[6]} {u_nes/u_apu/u_core_6502/cpu_cycle[7]} {u_nes/u_apu/u_core_6502/cpu_cycle[8]} {u_nes/u_apu/u_core_6502/cpu_cycle[9]} {u_nes/u_apu/u_core_6502/cpu_cycle[10]} {u_nes/u_apu/u_core_6502/cpu_cycle[11]} {u_nes/u_apu/u_core_6502/cpu_cycle[12]} {u_nes/u_apu/u_core_6502/cpu_cycle[13]} {u_nes/u_apu/u_core_6502/cpu_cycle[14]} {u_nes/u_apu/u_core_6502/cpu_cycle[15]} {u_nes/u_apu/u_core_6502/cpu_cycle[16]} {u_nes/u_apu/u_core_6502/cpu_cycle[17]} {u_nes/u_apu/u_core_6502/cpu_cycle[18]} {u_nes/u_apu/u_core_6502/cpu_cycle[19]} {u_nes/u_apu/u_core_6502/cpu_cycle[20]} {u_nes/u_apu/u_core_6502/cpu_cycle[21]} {u_nes/u_apu/u_core_6502/cpu_cycle[22]} {u_nes/u_apu/u_core_6502/cpu_cycle[23]} {u_nes/u_apu/u_core_6502/cpu_cycle[24]} {u_nes/u_apu/u_core_6502/cpu_cycle[25]} {u_nes/u_apu/u_core_6502/cpu_cycle[26]} {u_nes/u_apu/u_core_6502/cpu_cycle[27]} {u_nes/u_apu/u_core_6502/cpu_cycle[28]} {u_nes/u_apu/u_core_6502/cpu_cycle[29]} {u_nes/u_apu/u_core_6502/cpu_cycle[30]} {u_nes/u_apu/u_core_6502/cpu_cycle[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 16 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {u_nes/cpu_addr[0]} {u_nes/cpu_addr[1]} {u_nes/cpu_addr[2]} {u_nes/cpu_addr[3]} {u_nes/cpu_addr[4]} {u_nes/cpu_addr[5]} {u_nes/cpu_addr[6]} {u_nes/cpu_addr[7]} {u_nes/cpu_addr[8]} {u_nes/cpu_addr[9]} {u_nes/cpu_addr[10]} {u_nes/cpu_addr[11]} {u_nes/cpu_addr[12]} {u_nes/cpu_addr[13]} {u_nes/cpu_addr[14]} {u_nes/cpu_addr[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 8 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {u_nes/data_from_cpu[0]} {u_nes/data_from_cpu[1]} {u_nes/data_from_cpu[2]} {u_nes/data_from_cpu[3]} {u_nes/data_from_cpu[4]} {u_nes/data_from_cpu[5]} {u_nes/data_from_cpu[6]} {u_nes/data_from_cpu[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 8 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {u_nes/data_from_ppu[0]} {u_nes/data_from_ppu[1]} {u_nes/data_from_ppu[2]} {u_nes/data_from_ppu[3]} {u_nes/data_from_ppu[4]} {u_nes/data_from_ppu[5]} {u_nes/data_from_ppu[6]} {u_nes/data_from_ppu[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 8 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {u_nes/data_to_cpu[0]} {u_nes/data_to_cpu[1]} {u_nes/data_to_cpu[2]} {u_nes/data_to_cpu[3]} {u_nes/data_to_cpu[4]} {u_nes/data_to_cpu[5]} {u_nes/data_to_cpu[6]} {u_nes/data_to_cpu[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 5 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {u_nes/nes_phase[0]} {u_nes/nes_phase[1]} {u_nes/nes_phase[2]} {u_nes/nes_phase[3]} {u_nes/nes_phase[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 14 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {u_nes/ppu_addr[0]} {u_nes/ppu_addr[1]} {u_nes/ppu_addr[2]} {u_nes/ppu_addr[3]} {u_nes/ppu_addr[4]} {u_nes/ppu_addr[5]} {u_nes/ppu_addr[6]} {u_nes/ppu_addr[7]} {u_nes/ppu_addr[8]} {u_nes/ppu_addr[9]} {u_nes/ppu_addr[10]} {u_nes/ppu_addr[11]} {u_nes/ppu_addr[12]} {u_nes/ppu_addr[13]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 8 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {u_nes/ppu_data_i[0]} {u_nes/ppu_data_i[1]} {u_nes/ppu_data_i[2]} {u_nes/ppu_data_i[3]} {u_nes/ppu_data_i[4]} {u_nes/ppu_data_i[5]} {u_nes/ppu_data_i[6]} {u_nes/ppu_data_i[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 8 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {u_nes/ppu_data_o[0]} {u_nes/ppu_data_o[1]} {u_nes/ppu_data_o[2]} {u_nes/ppu_data_o[3]} {u_nes/ppu_data_o[4]} {u_nes/ppu_data_o[5]} {u_nes/ppu_data_o[6]} {u_nes/ppu_data_o[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list u_nes/cpu_rw]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list u_nes/nmi]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list u_nes/ppu_rw]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets u_ila_0_clk_nes]
