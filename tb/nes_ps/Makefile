
include ../../inc/make.inc

TOP=nes_tb
BD_SOURCE = cart_mem_bd.tcl
LOCAL_SRC = $(TOP).sv $(abspath cart_top.sv) $(abspath axi_cart_regs.v)
HDL_SOURCE = $(AUDIO_SOURCE) $(HDMI_SOURCE) $(PPU_SOURCE) $(CPU_SOURCE) $(NES_SOURCE) $(LOCAL_SRC)
# TOP=test_ps_top
# BD_SOURCE = test_bd.tcl
# LOCAL_SRC = $(TOP).sv $(abspath axi_regs.v)
# HDL_SOURCE = $(LOCAL_SRC)
DEVICE=xc7z010clg400-1
DEVICE_SHORT=xc7z010_1


include ../../inc/make.hw

