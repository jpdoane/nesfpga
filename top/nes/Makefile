
include ../../inc/make.inc

TOP=nes_top
BD_SOURCE = cart_ps_bd.tcl
LOCAL_SRC = $(TOP).sv 
HDL_SOURCE = $(AUDIO_SOURCE) $(HDMI_SOURCE) $(PPU_SOURCE) $(CPU_SOURCE) $(NES_SOURCE) $(CART_SOURCE) $(LOCAL_SRC)
# TOP=test_ps_top
# BD_SOURCE = test_bd.tcl
# LOCAL_SRC = $(TOP).sv $(abspath axi_regs.v)
# HDL_SOURCE = $(LOCAL_SRC)
DEVICE=xc7z010clg400-1
DEVICE_SHORT=xc7z010_1

DEBUG_NETS = debug_nets.tcl

include ../../inc/make.hw

NES_FILE=$(PROJ_ROOT)/roms/smb.nes
CART_INCL=$(abspath build/cart_incl.sv)
$(CART_INCL): $(NES_FILE)
	-@mkdir build
	cd build && $(PROJ_ROOT)/tools/nes2mem.py $(NES_FILE) $(CART_INCL)

prebuild: $(CART_INCL)



