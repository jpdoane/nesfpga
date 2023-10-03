setws ./workspace
app create -name nes_fsbl -hw {/home/jpdoane/nesfpga/top/nes_ps/build_smb/impl/nes_top.xsa}  -os standalone -proc ps7_cortexa9_0
app config -name nes_fsbl -add libraries xilffs
# app config -name nes_fsbl define-compiler-symbols {FSBL_DEBUG_INFO}
app build -name nes_fsbl
