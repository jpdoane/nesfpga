#include <xil_types.h>
#include "ff.h"
#include "xil_printf.h"
#include <xstatus.h>
#include "xil_cache.h"

#define MAPPER_MIRRORV 0x100;
#define MAPPER_CHRRAM 0x200;
#define MAPPER_PRGRAM 0x400;

int SD_Init();
int SD_Eject();
int get_file (FILINFO *fno, const char *path, int index);
int list_dir (const char *path);
int ReadNESFile(char *FileName, u32 *cart_addr, u32 *CHR_addr, u32 *PRG_addr, u32 *PRGRAM_addr);

//int ReadFile(char *FileName, u32 DestinationAddress);
//int WriteFile(char *FileName, u32 size, u32 SourceAddress);
