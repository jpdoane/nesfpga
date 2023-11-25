include ../../inc/make.inc

TOP=nes_tb
VERILATE_TOP=nes_main.cpp
VERILATE_INCL=input.vc
HDL_SOURCE = $(AUDIO_SOURCE) $(PPU_SOURCE) $(CPU_SOURCE) $(NES_SOURCE) $(CART_SOURCE) hdmi_trigger.sv $(TOP).sv
VERILATE_ARGS= --max_frames 218 --skip_frames 215

include ../../inc/make.verilator

ROM_PATH=/home/jpdoane/nesroms
NES_FILE=$(ROM_PATH)/zelda.nes
# NES_FILE=$(ROM_PATH)/pacman.nes
NES_SAV_FILE=$(ROM_PATH)/zelda.sav
# NES_FILE=/home/jpdoane/nes-test-roms/apu_test/roms/7-dmc_basics.nes
# NES_FILE=/home/jpdoane/nes-test-roms/apu_test/roms/8-dmc_rates.nes
# NES_FILE=/home/jpdoane/nes-test-roms/apu_mixer/roms/square_sweep.nes
# NES_FILE=$(ROM_PATH)/oam_stress.nes
# NES_FILE=/home/jpdoane/nes-test-roms/oam_dma/oam_dma.nes
# NES_FILE=$(PROJ_ROOT)/rom_loader/build/loader.nes


CART_INCL=$(abspath obj_dir/cart_incl.sv)
$(CART_INCL):
	-@mkdir obj_dir
	cd obj_dir && $(PROJ_ROOT)/tools/nes2mem.py $(NES_FILE) $(CART_INCL) $(NES_SAV_FILE)

.PHONY: cart prebuild
cart:
	make $(CART_INCL)
prebuild: cart

VERILATOR_FLAGS += -DCART_INCL='"$(CART_INCL)"'

animate: 
	@convert -delay 5 -loop 0 $(sort $(wildcard logs/*.ppm)) logs/animated.gif