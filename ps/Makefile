TOP=nes_top

LIBS := -Wl,--start-group,-lxil,-lgcc,-lc,--end-group -Wl,--start-group,-lxilffs,-lxil,-lgcc,-lc,--end-group
TOOL = arm-none-eabi
TOOL_PATH = /tools/Xilinx/Vitis/2023.1/gnu/aarch32/lin/gcc-$(TOOL)/bin/
GCC = $(TOOL_PATH)/$(TOOL)-gcc
SIZE_TOOL = $(TOOL_PATH)/$(TOOL)-size

BSP = $(abspath ./workspace/NESFPGA/export/NESFPGA/sw/NESFPGA/A9_Standalone)
BSP_LIBPATH = $(BSP)/bsplib/lib
BSP_INCPATH = $(BSP)/bspinclude/include

LINKER_SCRIPT = lscript.ld
GCC_FLAGS = -Wall -O0 -g3 -c -fmessage-length=0 -mcpu=cortex-a9 -mfpu=vfpv3 -mfloat-abi=hard -I$(BSP_INCPATH)
LINKER_FLAGS = -mcpu=cortex-a9 -mfpu=vfpv3 -mfloat-abi=hard -Wl,-build-id=none -specs=Xilinx.spec -Wl,-T -Wl,$(LINKER_SCRIPT) -L$(BSP_LIBPATH)

PL_PATH=$(abspath ../top/nes/build/impl)
TARGET=$(abspath build/nes_loader.elf)
FSBL=$(abspath workspace/nes_fsbl/Debug/nes_fsbl.elf)
BIT=$(abspath build/nes.bit)
XSA=$(abspath build/nes.xsa)
BIF=$(abspath workspace/output.bif)
BOOT=$(abspath workspace/BOOT.bin)
ROM_LOADER=$(abspath ../rom_loader/build/loader.nes)

PS_SOURCE = $(wildcard src/*.c) $(wildcard src/*.cpp)
PS_OBJS = $(patsubst src/%.c,build/%.o,$(PS_SOURCE))

BUILD_ENV=build/.build

# All Target
all: $(TARGET)

run: $(TARGET)
	xsct load.tcl

build/%.o: src/%.c $(BUILD_ENV)
	$(GCC) $(GCC_FLAGS) -o $@ $<

$(TARGET): lscript.ld $(PS_OBJS)
	$(GCC) $(LINKER_FLAGS) -o $@ $(PS_OBJS) $(LIBS)


$(BUILD_ENV): $(PL_PATH)/$(TOP).bit $(PL_PATH)/$(TOP).xsa
	-rm -r workspace
	@mkdir -p build
	cp $(PL_PATH)/$(TOP).bit $(BIT)
	cp $(PL_PATH)/$(TOP).xsa $(XSA)
	xsct fsbl.tcl
	touch $(BUILD_ENV)

$(BIT): $(BUILD_ENV)
$(XSA): $(BUILD_ENV)
$(FSBL): $(BUILD_ENV)
$(BSP): $(BUILD_ENV)

$(BIF): $(BUILD_ENV) $(TARGET) $(BIT) $(XSA)
	echo "the_ROM_image:" > $(BIF)
	echo "{" >> $(BIF)
	echo "[bootloader]$(FSBL)" >> $(BIF)
	echo $(BIT) >> $(BIF)
	echo $(TARGET) >> $(BIF)
	echo "[load = 0x2000000] $(ROM_LOADER)" >> $(BIF)
	echo "}" >> $(BIF)

$(BOOT): $(BIF)
	bootgen -image $(BIF) -arch zynq -o $(BOOT) -w

flash: $(BIF) $(BOOT) $(TARGET) $(FSBL)
	program_flash -f $(BOOT) -offset 0 -flash_type qspi-x4-single -fsbl $(FSBL) -url TCP:127.0.0.1:3121 

# Other Targets
clean:
	-rm -rf build
	-rm -rf workspace

.PHONY: all run clean flash image #dependents main-build pre-build  secondary-outputs
