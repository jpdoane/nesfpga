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

#include "ines_sdcard.h"
#include "nes_io.h"
extern FATFS  fatfs;

#define ASCII_ESC 27

int main() {


//	u32 *reg = (u32 *) CART_ADDR;
//
//	u32 nn;
//	for(nn=0;nn<4;nn++){
//		reg[0] = nn;
//		xil_printf("reg: 0x%x\r\n", nn);
//		Xil_DCacheFlush();
//		getchar();
//	}

//	xil_printf( "%c[2J", ASCII_ESC ); //clr screen

	int Status;
    Status = SD_Init(&fatfs);
    if (Status != XST_SUCCESS) {
    	xil_printf("file system init failed\r\n");
    	 return XST_FAILURE;
    }

	FRESULT res;
	FILINFO fno;
	int sel, sel_old;

	sel_old = -1;

	u32* cart_config;
	cart_config = (u32*) CART_ADDR;


	int num_games = 0;
	res = list_nesfiles ("", &num_games);
	int start_count = 0;
	int current_game = 1;

	get_nesfile(&fno, "", current_game);
	ReadNESFile(fno.fname, (u32*) CART_ADDR, (u32*) CHR_ADDR, (u32*) PRG_ADDR, (u32*) PRGRAM_ADDR);

	while (1) {

		start_count = 0;
		while( cart_config[3] & 0x4 ) {
			usleep(1000);
			start_count++;
			if(start_count >= 3000){
				xil_printf("Select button held down for 3 sec, switching games...\r\n");

				//before switching, save game
				if (cart_config[1] & 0x20000 )
					writeSaveFile(fno.fname, (u32*) PRGRAM_ADDR, 0x2000);

				current_game++;
				if(current_game>num_games) current_game = 1;

				get_nesfile(&fno, "", current_game);
				ReadNESFile(fno.fname, (u32*) CART_ADDR, (u32*) CHR_ADDR, (u32*) PRG_ADDR, (u32*) PRGRAM_ADDR);
				break;
			}
		}
		usleep(100000);
		// xil_printf("buttons: 0x%x\r\n",cart_config[3] & 0xff);
	}


}




