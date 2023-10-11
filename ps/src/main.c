#include "xparameters.h"
#include "xil_printf.h"
#include "xil_types.h"
#include <stdio.h>
#include <sleep.h>

// Get device IDs from xparameters.h
#define CART_ADDR XPAR_MCART_AXI_BASEADDR
#define CHR_ADDR XPAR_BRAM_0_BASEADDR
#define PRG_ADDR XPAR_BRAM_1_BASEADDR
#define PRGRAM_ADDR XPAR_BRAM_2_BASEADDR
#define ROM_LOADER_ADDR 0x2000000

#include "ines_sdcard.h"
#include "nes_io.h"
extern FATFS  fatfs;

#define ASCII_ESC 27
int loadROMLoader();

int main() {

	int Status;
    Status = SD_Init(&fatfs);
    if (Status != XST_SUCCESS) {
    	xil_printf("file system init failed\r\n");
    	 return XST_FAILURE;
    }

	FILINFO fno;

	int num_games = 0;
	int start_count = 0;
	int quit_game = 0;
	int nn;
	u8* wram = (u8*) PRGRAM_ADDR;
	u32* cart_config = (u32*) CART_ADDR;
	char* rom_table;

	xil_printf("\n\n\n\n\n\n\n\nROMs found:\r\n");
	list_nesfiles ("", &num_games);

	while (1) {
		// clear rom selection flag
		wram[0x1fff] = 0;
		wram[0x1ffe] = 0;

		// initialize WRAM with list of roms
		rom_table = (char*) wram;
		for (nn=1;nn<=num_games; nn++) {
			get_nesfile(&fno, "", nn);
			strcpy( (char*) rom_table, fno.fname);
			rom_table += strlen(fno.fname)+1;
		}
		*rom_table = 0; // end of table

		// start loader rom
		xil_printf("Starting loader ROM\r\n");
		loadROMLoader();
		xil_printf("running loader ROM\r\n");
		// ReadNESFile("loader.nes", (u32*) CART_ADDR, (u32*) CHR_ADDR, (u32*) PRG_ADDR, (u32*) PRGRAM_ADDR);

		// poll selection flag
		while ( wram[0x1fff]==0 ){
			// xil_printf("sel: %d %d\r\n", wram[0x1fff], wram[0x1ffe]);
			usleep(10000);
		}

		nn = wram[0x1ffe]+1;
		get_nesfile(&fno, "", nn);
		xil_printf("ROM number %d selected: %s\r\n", nn, fno.fname);

		// load selected rom
		xil_printf("Booting %s...\r\n", fno.fname);
		ReadNESFile(fno.fname, (u32*) CART_ADDR, (u32*) CHR_ADDR, (u32*) PRG_ADDR, (u32*) PRGRAM_ADDR);

    	// wait for long start press
		quit_game=0;
		while (!quit_game) {
			start_count = 0;
			while( cart_config[3] & 0xc ) { 
				usleep(1000);
				start_count++;
				if(start_count >= 1000){
					xil_printf("Select & Start button held down, switching games...\r\n");
					if (cart_config[1] & 0x20000 )
						writeSaveFile(fno.fname, (u32*) PRGRAM_ADDR, 0x2000);

					quit_game = 1;
					break;
				}
			}
			usleep(100000);
		}
	}

}

int loadROMLoader()
{
	u32* loader = (u32*) ROM_LOADER_ADDR;
	u32* cart_config = (u32*) CART_ADDR;

 	// reset system while we load new data
	cart_config[0] = 1;

 	// load header
	cart_config[1] = loader[1];
	cart_config[2] = loader[2];
	loader += 4;	// increment 16bytes, 4 words

	// load prg
	memcpy ( (void*) PRG_ADDR, (void*) loader, 0x8000 );
	loader += 0x2000; // increment 32kB = 8kwords

	// load chr
	memcpy ( (void*) CHR_ADDR, (void*) loader, 0x2000 );

	// boot
	cart_config[0] = 0;

	return XST_SUCCESS;
}
