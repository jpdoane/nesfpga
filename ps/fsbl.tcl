setws ./workspace
# app create -name nes_fsbl -hw {build/nes.xsa}  -os standalone -proc ps7_cortexa9_0
# app config -name nes_fsbl -add libraries xilffs
# # app config -name nes_fsbl define-compiler-symbols {FSBL_DEBUG_INFO}
# app build -name nes_fsbl

platform create -name NESFPGA -hw {build/nes.xsa} -no-boot-bsp
domain create -name A9_Standalone -os standalone -proc ps7_cortexa9_0
domain active A9_Standalone
bsp setlib -name xilffs
# bsp config zynq_fsbl_bsp true
platform generate
app create -name nes_fsbl -platform NESFPGA -template "Zynq FSBL" -domain A9_Standalone -lang c
app build -name nes_fsbl