#include "xparameters.h"
#include "xil_printf.h"
#include "xil_types.h"
#include <stdio.h>

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

	while (1) {
		xil_printf("NESFPGA\r\nSelect ROM:\r\n\r\n");
		res = list_nesfiles ("");
		if (res != FR_OK) {
			xil_printf("Error reading SD Card\r\n");
			break;
		}

		sel = get_user_selection(10);

		// if (sel_old > 0 && (cart_config[0] & MAPPER_PRGRAM) )
		// {
		// 	//save last game
		// 	get_nesfile(&fno, "", sel_old);
		// 	writeSaveFile(fno.fname, (u32*) PRGRAM_ADDR, cart_config[3]+1);
		// }
		// sel_old = sel;


		res = get_nesfile(&fno, "", sel);
		if (res != FR_OK) {
			xil_printf("Error reading file %s\r\n", fno.fname);
			break;
		}
		xil_printf("Reading file %s\r\n", fno.fname);


		ReadNESFile(fno.fname, (u32*) CART_ADDR, (u32*) CHR_ADDR, (u32*) PRG_ADDR, (u32*) PRGRAM_ADDR);
	}


}




