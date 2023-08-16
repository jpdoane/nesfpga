
include ../../inc/make.inc

TOP=cpu_tb

HDL_SOURCE = $(CPU_SOURCE) \
			 $(PROJ_ROOT)/modules/nes/cpu_mmap.sv \
			 $(TOP).sv

CUSTOMSIMARGS=-D'PALFILE="$(PROJ_ROOT)/roms/nes.mem"' \
			  -D'ROM_PATH="$(PROJ_ROOT)/roms/nestest/"' \
			  -D'RESET_RAM=1' \
			  -D'DEBUG_CPU=1' \
			  -I $(CPU_INC)

include ../../inc/make.sim

