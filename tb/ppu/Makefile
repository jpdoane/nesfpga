
include ../../inc/make.inc

TOP=ppu_tb
HDL_SOURCE = $(CLK_SOURCE) $(HDMI_SOURCE) $(PPU_SOURCE) cpu_sim.sv video_png.sv $(TOP).sv
CUSTOMSIMARGS=-D'PALFILE="$(PROJ_ROOT)/roms/nes.mem"' -D'ROM_PATH="$(PROJ_ROOT)/roms/smb_ppu/"'

include ../../inc/make.sim

