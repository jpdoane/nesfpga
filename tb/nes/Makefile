include ../../inc/make.inc

TOP=nes_tb
VERILATE_TOP=nes_main.cpp
VERILATE_INCL=input.vc
HDL_SOURCE = $(PPU_SOURCE) $(CPU_SOURCE) $(NES_SOURCE) hdmi_trigger.sv $(TOP).sv
VERILATE_ARGS= --max_frames 34 --skip_frames 32

include ../../inc/make.verilator

show:
	echo $(abspath .)/$(TOP).sav

animate: 
	@convert -delay 5 -loop 0 $(sort $(wildcard logs/*.ppm)) logs/animated.gif