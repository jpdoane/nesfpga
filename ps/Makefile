################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf


LIBS := -Wl,--start-group,-lxil,-lgcc,-lc,--end-group -Wl,--start-group,-lxilffs,-lxil,-lgcc,-lc,--end-group
TOOL = arm-none-eabi
TOOL_PATH = /tools/Xilinx/Vitis/2023.1/gnu/aarch32/lin/gcc-$(TOOL)/bin/
GCC = $(TOOL_PATH)/$(TOOL)-gcc
SIZE_TOOL = $(TOOL_PATH)/$(TOOL)-size

BSP_LIBPATH = /home/jpdoane/workspace/nes_top/export/nes_top/sw/nes_top/standalone_ps7_cortexa9_0/bsplib/lib
LINKER_SCRIPT = lscript.ld
GCC_FLAGS = -Wall -O0 -g3 -c -fmessage-length=0 -mcpu=cortex-a9 -mfpu=vfpv3 -mfloat-abi=hard -I/home/jpdoane/workspace/nes_top/export/nes_top/sw/nes_top/standalone_ps7_cortexa9_0/bspinclude/include
LINKER_FLAGS = -mcpu=cortex-a9 -mfpu=vfpv3 -mfloat-abi=hard -Wl,-build-id=none -specs=Xilinx.spec -Wl,-T -Wl,$(LINKER_SCRIPT) -L$(BSP_LIBPATH)

#    -mcpu=cortex-a9 -mfpu=vfpv3 -mfloat-abi=hard -Wl,-build-id=none -specs=Xilinx.spec -Wl,-T -Wl,$(LINKER_SCRIPT) -L$(BSP_LIBPATH) -o $@ $(PS_OBJS) $(LIBS)

#-specs=Xilinx.spec 

# All of the sources participating in the build are defined here
-include sources.mk
-include src/subdir.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 
ELFSIZE += build/nes_loader.elf.size


# All Target
all:
	$(MAKE) --no-print-directory main-build

run: build/nes_loader.elf
	xsct load.tcl

# Main-build Target
main-build: build/nes_loader.elf secondary-outputs

PS_SOURCE = $(wildcard src/*.c) $(wildcard src/*.cpp)
PS_OBJS = $(patsubst src/%.c,build/%.o,$(PS_SOURCE))

# Tool invocations
build/%.o: src/%.c
	-mkdir build
	$(GCC) $(GCC_FLAGS) -o $@ $<

build/nes_loader.elf: lscript.ld $(PS_OBJS)
	$(GCC) $(LINKER_FLAGS) -o $@ $(PS_OBJS) $(LIBS)

build/nes_loader.elf.size: build/nes_loader.elf
	$(SIZE_TOOL) $< |tee $@


# Other Targets
clean:
	-$(RM) build

# pre-build:
# 	-a9-linaro-pre-build-step
# 	-@echo ' '

secondary-outputs: $(ELFSIZE)

.PHONY: all run clean dependents main-build pre-build  secondary-outputs

-include ../makefile.targets
