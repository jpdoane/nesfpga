#include "ines_sdcard.h"
#include <stdio.h>
#include <string.h>

FATFS  fatfs;

int is_nes(const char* filename)
{
	return strcmp(strrchr(filename, '.') , ".NES" )==0;
}
	
int list_nesfiles (const char *path, int* num)
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
	if(num) *num = nfile;
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
	u32 header[4];
	u32 CHR_sz;
	u32 PRG_sz;

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
	if ( header[0] != 0x1a53454e) {
		xil_printf(" ERROR : %s is not a valid INES file %d\r\n", FileName);
		return XST_FAILURE;
	}

	xil_printf("Loading %s...\r\n", FileName);

 	// reset system while we load new data
	cart_addr[0] = 1;

 	// load header
	cart_addr[1] = header[1];
	cart_addr[2] = header[2];

	PRG_sz = 16384 * (header[1] & 0xff);
	xil_printf("Loading %dB PRG ROM\r\n", PRG_sz);
	rc = f_read(&fil, (void*) PRG_addr, PRG_sz, &br);
	if (rc) {
		xil_printf(" ERROR : f_read returned %d\r\n", rc);
		return XST_FAILURE;
	}
	// xil_printf("PRG_sz = %d, br= %d\r\n", PRG_sz, br);
	// xil_printf("PRG[%d-1] = 0x%x?\r\n", br/4, PRG_addr[br/4-1]);

	CHR_sz = 8192 *  ((header[1] & 0xff00) >> 8);
	xil_printf("Loading %dB CHR ROM\r\n", CHR_sz);
	rc = f_read(&fil, (void*) CHR_addr, CHR_sz, &br);
	if (rc) {
		xil_printf(" ERROR : f_read returned %d\r\n", rc);
		return XST_FAILURE;
	}

	if (header[1] & 0x20000)
		readSaveFile(FileName, PRGRAM_addr, 0x2000);

	rc = f_close(&fil);
	if (rc) {
		xil_printf(" ERROR : f_close returned %d\r\n", rc);
		return XST_FAILURE;
	}

	// clear reset.  NES should now boot
	cart_addr[0] = 0;

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

