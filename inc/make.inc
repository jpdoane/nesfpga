SCRIPTS = $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
PROJ_ROOT = $(abspath $(SCRIPTS)/..)

ARTYZ7_XDC =  $(SCRIPTS)/artyz7.xdc

CPU_SOURCE = $(wildcard $(PROJ_ROOT)/modules/6502/hdl/*.sv)
CLK_SOURCE = $(wildcard $(PROJ_ROOT)/hdl/clocks/*.sv)
PPU_SOURCE = $(wildcard $(PROJ_ROOT)/hdl/ppu/*.sv)
HDMI_SOURCE = $(wildcard $(PROJ_ROOT)/hdl/hdmi/*.sv)
AUDIO_SOURCE = $(wildcard $(PROJ_ROOT)/hdl/audio/*.sv)
NES_SOURCE = $(wildcard $(PROJ_ROOT)/hdl/nes/*.sv)
CART_SOURCE = $(wildcard $(PROJ_ROOT)/hdl/carts/*.sv)

CPU_INC = $(PROJ_ROOT)/modules/6502/hdl/  $(PROJ_ROOT)/modules/6502/hdl/debug/

CONSTRAINTS = $(wildcard  $(PROJ_ROOT)/boards/artyz7/*.xdc)

BEEP_GOOD=/usr/share/sounds/Oxygen-Sys-App-Positive.ogg
BEEP_BAD=/usr/share/sounds/Oxygen-Sys-App-Error-Serious-Very.ogg
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

FAIL = (echo $(RED)$(1) failed$(NC); $(2) && paplay $(BEEP_BAD); exit 1)
SUCCEED = (echo $(GREEN)$(1) succeeded$(NC); $(2) && paplay $(BEEP_GOOD); exit 0)
# to use
# 	command || $(call FAIL, COMMAND_NAME, true)
# 	$(call SUCCEED, COMMAND_NAME, false)
#
# final true/false indicates whether to play a sound

GAME=$(shell cat current_game)

_default: default

GAMES=zelda smb
$(GAMES):
	@echo $@ > current_game
