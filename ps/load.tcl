# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: /home/jpdoane/workspace/nes_loader_system/_ide/scripts/debugger_nes_loader-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source /home/jpdoane/workspace/nes_loader_system/_ide/scripts/debugger_nes_loader-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 1000
targets -set -filter {jtag_cable_name =~ "Digilent Arty Z7 003017A6B59CA" && level==0 && jtag_device_ctx=="jsn-Arty Z7-003017A6B59CA-13722093-0"}
fpga -file /home/jpdoane/nesfpga/top/nes_ps/build_smb/impl/nes_top.bit
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw /home/jpdoane/workspace/nes_top/export/nes_top/hw/nes_top.xsa -mem-ranges [list {0x40000000 0xbfffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
source ps7_init.tcl
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "*A9*#0"}
dow build/nes_loader.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "*A9*#0"}
con
