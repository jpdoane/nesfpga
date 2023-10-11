include ../../inc/make.inc

TOP=nes_tb
VERILATE_TOP=nes_main.cpp
VERILATE_INCL=input.vc
HDL_SOURCE = $(AUDIO_SOURCE) $(PPU_SOURCE) $(CPU_SOURCE) $(NES_SOURCE) $(CART_SOURCE) hdmi_trigger.sv $(TOP).sv
VERILATE_ARGS= --max_frames 50 --skip_frames 17

include ../../inc/make.verilator

NES_FILE=$(PROJ_ROOT)/roms/smb.nes
CART_INCL=$(abspath obj_dir/cart_incl.sv)
$(CART_INCL): $(NES_FILE)
	-@mkdir obj_dir
	cd obj_dir && $(PROJ_ROOT)/tools/nes2mem.py $(NES_FILE) $(CART_INCL)

prebuild: $(CART_INCL)

VERILATOR_FLAGS += -DCART_INCL='"$(CART_INCL)"'

animate: 
	@convert -delay 5 -loop 0 $(sort $(wildcard logs/*.ppm)) logs/animated.gif