#include "ines_sdcard.h"
#include <stdio.h>
#include <string.h>

FATFS  fatfs;

int is_nes(const char* filename)
{
	return strcmp(strrchr(filename, '.') , ".NES" )==0;
}
	
int list_nesfiles (const char *path)
{
    FRESULT res;
    DIR dir;
    FILINFO fno;
    int nfile, ndir;

    res = f_opendir(&dir, path);                       /* Open the directory */
    if (res == FR_OK) {
        nfile = ndir = 0;
        for (;;) {
            res = f_readdir(&dir, &fno);                   /* Read a directory item */
            if (res != FR_OK || fno.fname[0] == 0) break;  /* Error or end of dir */
            if (fno.fattrib & AM_DIR) {            /* Directory */
            	// xil_printf("   <DIR>   %s\r\n", fno.fname);
                // ndir++;
            } else if (is_nes(fno.fname)) {                               /* NES File */
            	xil_printf("%3u: %s\r\n", ++nfile, fno.fname);
            }
        }
        f_closedir(&dir);
        xil_printf("%d dirs, %d NES files.\r\n", ndir, nfile);
    } else {
    	xil_printf("Failed to open \"%s\". (%u)\r\n", path, res);
    }
    return res;
}

int list_dir (const char *path)
{
    FRESULT res;
    DIR dir;
    FILINFO fno;
    int nfile, ndir;

    res = f_opendir(&dir, path);                       /* Open the directory */
    if (res == FR_OK) {
        nfile = ndir = 0;
        for (;;) {
            res = f_readdir(&dir, &fno);                   /* Read a directory item */
            if (res != FR_OK || fno.fname[0] == 0) break;  /* Error or end of dir */
            if (fno.fattrib & AM_DIR) {            /* Directory */
            	xil_printf("   <DIR>   %s\r\n", fno.fname);
                ndir++;
            } else {                               /* File */
            	xil_printf("%3u: %s\r\n", ++nfile, fno.fname);
            }
        }
        f_closedir(&dir);
        xil_printf("%d dirs, %d files.\r\n", ndir, nfile);
    } else {
    	xil_printf("Failed to open \"%s\". (%u)\r\n", path, res);
    }
    return res;
}

int get_nesfile(FILINFO *fno, const char *path, int index)
{
    FRESULT res;
    DIR dir;
    int nfile, ndir;

    res = f_opendir(&dir, path);                       /* Open the directory */
    if (res == FR_OK) {
        nfile = ndir = 0;
        while (nfile<index) {
            res = f_readdir(&dir, fno);                   /* Read a directory item */
            if (res != FR_OK || fno->fname[0] == 0) {
            	break;  /* Error or end of dir */
            }
            if (!(fno->fattrib & AM_DIR) && is_nes(fno->fname) ) nfile++;
        }
        f_closedir(&dir);
    }
    return res;
}

int get_file (FILINFO *fno, const char *path, int index)
{
    FRESULT res;
    DIR dir;
    int nfile, ndir;

    res = f_opendir(&dir, path);                       /* Open the directory */
    if (res == FR_OK) {
        nfile = ndir = 0;
        while (nfile<index) {
            res = f_readdir(&dir, fno);                   /* Read a directory item */
            if (res != FR_OK || fno->fname[0] == 0) {
            	break;  /* Error or end of dir */
            }
            if (! (fno->fattrib & AM_DIR) ) nfile++;
        }
        f_closedir(&dir);
    }
    return res;
}

int SD_Init()
{
	FRESULT rc;
	TCHAR *Path = "0:/";
	rc = f_mount(&fatfs,Path,0);
	if (rc) {
		xil_printf(" ERROR : f_mount returned %d\r\n", rc);
		return XST_FAILURE;
	}
	return XST_SUCCESS;
}

int SD_Eject()
{
	FRESULT rc;
	TCHAR *Path = "0:/";
	rc = f_mount(0,Path,1);
	if (rc) {
		xil_printf(" ERROR : f_mount returned %d\r\n", rc);
		return XST_FAILURE;
	}
	return XST_SUCCESS;
}


int ReadNESFile(char *FileName, u32 *cart_addr, u32 *CHR_addr, u32 *PRG_addr, u32 *PRGRAM_addr)
{

	FIL fil;
	FRESULT rc;
	UINT br;
	u8 header[16];
	u32 mapper;
	u32 CHR_sz;
	u32 PRG_sz;
	u32 PRGRAM_sz;
	u32 cart_config = 0;
	// u32 n;
	// u32 d;

	rc = f_open(&fil, FileName, FA_READ);
	if (rc) {
		xil_printf(" ERROR : f_open(%s) returned %d\r\n", FileName, rc);
		return XST_FAILURE;
	}
	rc = f_lseek(&fil, 0);
	if (rc) {
		xil_printf(" ERROR : f_lseek returned %d\r\n", rc);
		return XST_FAILURE;
	}

	// read header
	rc = f_read(&fil, (void*) header, 16, &br);
	if (rc) {
		xil_printf(" ERROR : f_read returned %d\r\n", rc);
		return XST_FAILURE;
	}
	if ( header[0] != 0x4e || header[1] != 0x45 || header[2] != 0x53 || header[3] != 0x1a ) {
		xil_printf(" ERROR : %s is not a valid INES file %d\r\n", FileName);
		return XST_FAILURE;
	}

	xil_printf("Loading %s...\r\n", FileName);
	mapper = header[6] >> 4;
	if ( mapper > 1 ) {
		xil_printf(" ERROR : mapper %d not supported\r\n", mapper);
		return XST_FAILURE;
	}

 	// reset system while we load new data
	cart_addr[0] = 0xffffffff;

	cart_config = (0xff & mapper); // set mapper
	if (header[6] & 0x1)
		cart_config |= MAPPER_MIRRORV; // set mirrorv

//	xil_printf("Header:\r\n");
//	for (n=0;n<16;n++) {
//		xil_printf("0x%x\r\n",header[n]);
//	}

	PRG_sz = 16384 * header[4];
	cart_addr[2] = PRG_sz-1;	// PRG addr mask
	xil_printf("Loading %dkB PRG ROM\r\n", header[4]*16);
	rc = f_read(&fil, (void*) PRG_addr, PRG_sz, &br);
	if (rc) {
		xil_printf(" ERROR : f_read returned %d\r\n", rc);
		return XST_FAILURE;
	}
	// xil_printf("PRG_sz = %d, br= %d\r\n", PRG_sz, br);
	// xil_printf("PRG[%d-1] = 0x%x?\r\n", br/4, PRG_addr[br/4-1]);

	CHR_sz = 8192 * header[5];
	if (CHR_sz == 0) {
		cart_addr[1] = 0x1fff;
		cart_config |= MAPPER_CHRRAM;
		xil_printf("Using 8k CHR-RAM\r\n");
	}
	else {
		cart_addr[1] = CHR_sz-1;
		xil_printf("Loading %dkB CHR-ROM\r\n", 8*header[5]);
		rc = f_read(&fil, (void*) CHR_addr, CHR_sz, &br);
		if (rc) {
			xil_printf(" ERROR : f_read returned %d\r\n", rc);
			return XST_FAILURE;
		}
	}
	// xil_printf("CHR_sz = %d, br= %d\r\n", CHR_sz, br);
	// xil_printf("CHR[%d-1] = 0x%x?\r\n", br/4, CHR_addr[br/4-1]);

	PRGRAM_sz = 8192 * header[8];
	if (PRGRAM_sz == 0) PRGRAM_sz = 8192;
	cart_addr[3] = PRGRAM_sz-1;
	cart_config |= MAPPER_PRGRAM;

	if (header[6] & 0x2) 
		readSaveFile(FileName, PRGRAM_addr, PRGRAM_sz);

	rc = f_close(&fil);
	if (rc) {
		xil_printf(" ERROR : f_close returned %d\r\n", rc);
		return XST_FAILURE;
	}

	// set config and disable reset.  NES should now boot
	cart_addr[0] = cart_config;

	xil_printf("Booting %s...\r\n", FileName);
	Xil_DCacheFlush();

	return XST_SUCCESS;
}


int readSaveFile(char *NESFileName, u32 *PRGRAM_addr, u32 sz)
{
	FIL fil;
	FRESULT rc;
	UINT br;

	char savefilename[13];

	strncpy(savefilename, NESFileName, 13);
	strcpy(strrchr(savefilename, '.') , ".SAV");

	xil_printf("Does save file exist at %s?\r\n", savefilename);

	rc = f_open(&fil, savefilename, FA_READ);
	if (rc != FR_OK) {
		xil_printf("Save file not found, PRGRAM will be uninitialized\r\n");
		return XST_FAILURE;
	}

	xil_printf("Loading PRGRAM from %s\r\n", savefilename);

	if (rc) {
		xil_printf("readSaveFile() ERROR : f_open returned %d\r\n", rc);
		return XST_FAILURE;
	}

	rc = f_read(&fil, (void*) PRGRAM_addr, sz, &br);
	if (rc || br!= sz) {
		xil_printf("readSaveFile() ERROR : failed to read save file %s\r\n", savefilename);
		return XST_FAILURE;
	}

	rc = f_close(&fil);
	if (rc) {
		xil_printf("readSaveFile() ERROR : f_close returned %d\r\n", rc);
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

int writeSaveFile(char *NESFileName, u32 *PRGRAM_addr, u32 sz)
{
	FIL fil;
	FRESULT rc;
	UINT br;

	char savefilename[13];

	strncpy(savefilename, NESFileName, 13);
	strcpy(strrchr(savefilename, '.') , ".SAV");

	xil_printf("saving PRGRAM to %s\r\n", savefilename);

	rc = f_open(&fil, savefilename, FA_CREATE_ALWAYS | FA_WRITE);
	if (rc) {
		xil_printf("writeSaveFile() ERROR : f_open returned %d\r\n", rc);
		return XST_FAILURE;
	}

	rc = f_write(&fil, (const void*) PRGRAM_addr, sz, &br);
	if (rc || br!= sz) {
		xil_printf("writeSaveFile() ERROR : failed to write save file %s\r\n", savefilename);
		return XST_FAILURE;
	}

	rc = f_close(&fil);
	if (rc) {
		xil_printf("writeSaveFile() ERROR : f_close returned %d\r\n", rc);
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}


//static int ReadFile(char *FileName, u32 addr, u32 offset, u32 sz)
//{
//	FIL fil;
//	FRESULT rc;
//	UINT br;
//	u32 file_size;
//	rc = f_open(&fil, FileName, FA_READ);
//	if (rc) {
//		xil_printf(" ERROR : f_open returned %d\r\n", rc);
//		return XST_FAILURE;
//	}
//	file_size = fil.fsize;
//	rc = f_lseek(&fil, offset);
//	if (rc) {
//		xil_printf(" ERROR : f_lseek returned %d\r\n", rc);
//		return XST_FAILURE;
//	}
//	rc = f_read(&fil, (void*) addr, sz, &br);
//	if (rc) {
//		xil_printf(" ERROR : f_read returned %d\r\n", rc);
//		return XST_FAILURE;
//	}
//	rc = f_close(&fil);
//	if (rc) {
//		xil_printf(" ERROR : f_close returned %d\r\n", rc);
//		return XST_FAILURE;
//	}
//	Xil_DCacheFlush();
//	return XST_SUCCESS;
//}

//
//static int WriteFile(char *FileName, u32 size, u32 SourceAddress){
//	UINT btw;
//	static FIL fil; // File instance
//	FRESULT rc; // FRESULT variable
//	rc = f_open(&fil, (char *)FileName, FA_OPEN_ALWAYS | FA_WRITE); //f_open
//	if (rc) {
//		xil_printf(" ERROR : f_open returned %d\r\n", rc);
//		return XST_FAILURE;
//	}
//	rc = f_write(&fil,(const void*)SourceAddress,size,&btw);
//	if (rc) {
//		xil_printf(" ERROR : f_write returned %d\r\n", rc);
//		return XST_FAILURE;
//	}
//	rc = f_close(&fil);
//	if (rc) {
//		xil_printf(" ERROR : f_write returned %d\r\n", rc);
//		return XST_FAILURE;
//	}
//	return XST_SUCCESS;
//}

