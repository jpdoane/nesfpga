
include ../../inc/make.inc

TOP=nes_tb
HDL_SOURCE = $(CLK_SOURCE) $(HDMI_SOURCE) $(PPU_SOURCE) $(CPU_SOURCE) $(NES_SOURCE) frame_record.sv $(TOP).sv
ROM_PATH=$(PROJ_ROOT)/roms/smb/
# ROM_PATH=$(PROJ_ROOT)/roms/nestest/
CUSTOMSIMARGS=-D'PALFILE="$(PROJ_ROOT)/roms/nes.mem"' \
			  -D'ROM_PATH="$(ROM_PATH)"' \
			  -I $(CPU_INC) \
			  -D'RESET_RAM=1' \
			  -D'DEBUG_CPU=1' \
			  -D'START_FRAME=30' \
			  -D'STOP_FRAME=35' \
			  -D'MAX_SIM_TIME=0'

			#   -pfileline=1


include ../../inc/make.sim

