include ../../inc/make.inc

TOP=nes_tb
VERILATE_TOP=nes_main.cpp
VERILATE_INCL=input.vc
HDL_SOURCE = $(AUDIO_SOURCE) $(PPU_SOURCE) $(CPU_SOURCE) $(NES_SOURCE) $(CART_SOURCE) hdmi_trigger.sv $(TOP).sv
VERILATE_ARGS= --max_frames 200 --skip_frames 1

include ../../inc/make.verilator

# NES_FILE=$(PROJ_ROOT)/roms/smb.nes
ROM_PATH=/home/jpdoane/nesroms
#NES_FILE=$(ROM_PATH)/castleva.nes
# NES_FILE=/home/jpdoane/nes-test-roms/apu_test/roms/2-len_table.nes
# NES_FILE=/home/jpdoane/nes-test-roms/apu_test/apu_test.nes
# NES_FILE=/home/jpdoane/nesfpga/rom_loader/build/loader.nes
NES_FILE=/home/jpdoane/nes-test-roms/apu_mixer/roms/square_sweep.nes
CART_INCL=$(abspath obj_dir/cart_incl.sv)
$(CART_INCL): $(NES_FILE)
	-@mkdir obj_dir
	cd obj_dir && $(PROJ_ROOT)/tools/nes2mem.py $(NES_FILE) $(CART_INCL)

.PHONY: cart prebuild
cart:
	make $(CART_INCL)
prebuild: cart

VERILATOR_FLAGS += -DCART_INCL='"$(CART_INCL)"'

animate: 
	@convert -delay 5 -loop 0 $(sort $(wildcard logs/*.ppm)) logs/animated.gif