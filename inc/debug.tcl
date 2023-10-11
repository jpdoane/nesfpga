create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list cart_ps_bd_i/processing_system7_0/inst/FCLK_CLK0]]

# add probe for each net listed in file

set fh [open "debug_nets.tcl" r]
set nprobes 0
while {[gets $fh netname] >= 0} {
    set nets [lsort -dictionary [get_nets "$netname*"]]
    # puts "Debugging net $net"
    # set nets {}
    # if {$max($net) < 0} {
    #     lappend nets [get_nets $net]
    # } else {
    #     # net is a bus name
    #     for {set i $min($net)} {$i <= $max($net)} {incr i} {
    #         lappend nets [get_nets $net[$i]]
    #     }
    # }
    set prb probe$nprobes
    if {$nprobes > 0} {
        create_debug_port u_ila_0 probe
    }
    set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/$prb]
    set_property port_width [llength $nets] [get_debug_ports u_ila_0/$prb]

    # connect_debug_port u_ila_0/probe0 [get_nets [list {u_nes_hdmi/u_nes/cpu_addr[0]} {u_nes_hdmi/u_nes/cpu_addr[1]} {u_nes_hdmi/u_nes/cpu_addr[2]} {u_nes_hdmi/u_nes/cpu_addr[3]} {u_nes_hdmi/u_nes/cpu_addr[4]} {u_nes_hdmi/u_nes/cpu_addr[5]} {u_nes_hdmi/u_nes/cpu_addr[6]} {u_nes_hdmi/u_nes/cpu_addr[7]} {u_nes_hdmi/u_nes/cpu_addr[8]} {u_nes_hdmi/u_nes/cpu_addr[9]} {u_nes_hdmi/u_nes/cpu_addr[10]} {u_nes_hdmi/u_nes/cpu_addr[11]} {u_nes_hdmi/u_nes/cpu_addr[12]} {u_nes_hdmi/u_nes/cpu_addr[13]} {u_nes_hdmi/u_nes/cpu_addr[14]} {u_nes_hdmi/u_nes/cpu_addr[15]} ]]
    connect_debug_port u_ila_0/$prb $nets
    incr nprobes
}
close $fh

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets AXI_CLK]
