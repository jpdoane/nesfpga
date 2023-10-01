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
	int sel;

	while (1) {
		xil_printf("NESFPGA\r\nSelect ROM:\r\n\r\n");
		res = list_dir ("");
		if (res != FR_OK) {
			xil_printf("Error reading SD Card\r\n");
			break;
		}

		sel = get_user_selection(10);

		res = get_file(&fno, "", sel);
		if (res != FR_OK) {
			xil_printf("Error reading file %s\r\n", fno.fname);
			break;
		}

		ReadNESFile(fno.fname, (u32*) CART_ADDR, (u32*) CHR_ADDR, (u32*) PRG_ADDR, (u32*) PRGRAM_ADDR);
	}


}




