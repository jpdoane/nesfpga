ASM_SOURCE = loader.s
BUILD_PATH=build
TARGET=$(BUILD_PATH)/loader.nes
CC=ca65

# compute 6502 obj from asm
build/%.o: %.s
	@mkdir -p $(BUILD_PATH)
	$(CC) -o $@ $^ -g -l $(BUILD_PATH)/labels.txt

$(TARGET): build/loader.o
	ld65 -o $(TARGET) -C loader.cfg $^ -m build/loader.map.txt -Ln build/loader.labels.txt --dbgfile build/loader.nes.dbg


.PHONY: obj, clean
obj: $(OBJFILE)

clean:
	@rm -r build