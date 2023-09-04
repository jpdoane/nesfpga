include ../../inc/make.inc

TOP=nes_tb
VERILATE_TOP=nes_main.cpp
VERILATE_INCL=input.vc
HDL_SOURCE = $(PPU_SOURCE) $(CPU_SOURCE) $(NES_SOURCE) $(CART_SOURCE) hdmi_trigger.sv $(TOP).sv
VERILATE_ARGS= --max_frames 60 --skip_frames 36

GAME=zelda

VERILATOR_FLAGS += -DCART=$(GAME)_cart
VERILATOR_FLAGS += -DSAVERAMS=1

include ../../inc/make.verilator

animate: 
	@convert -delay 5 -loop 0 $(sort $(wildcard logs/*.ppm)) logs/animated.gif