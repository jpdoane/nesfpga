#!/usr/bin/python3

import argparse, os
import argparse

def writemem(data, memfile):
    with open(memfile, 'w') as f_mem:
        f_mem.write("@0000\n")
        for byte in data:
            hex_repr = "{:02x}\n".format(byte)
            f_mem.write(hex_repr)

def writebin(data, binfile):
    with open(binfile, 'wb') as f:
        f.write(data)

def nes2mem(nes_file):
    with open(nes_file, 'rb') as fnes:
        header = fnes.read(16)
        writemem(header, "INES.mem")

        f6 = header[6]
        f7 = header[7]
        ines2 = (f7 & 0xc) > 0
        if ines2:
            print("ines 2.0 format")
        else:
            print("ines 1.0 format")

        NPRG = header[4]
        prg_sz = NPRG * 16384
        PRG = fnes.read(prg_sz)
        print(f"PRG size: {prg_sz} ({NPRG}x 16k blocks)")
        if NPRG == 1:
            print(f"Mirroring PRG to 16kB")
            PRG = PRG+PRG #fill 16kb
        writemem(PRG, "PRG.mem")
        writebin(PRG, "PRG.bin")

        NCHR = header[5]
        if NCHR == 0:
            print("uses CHR RAM...")
        else:
            chr_sz = NCHR * 8192
            CHR = fnes.read(chr_sz)
            print(f"CHR size: {chr_sz} ({NCHR}x 8k blocks)")
            writemem(CHR, "CHR.mem")
            writebin(CHR, "CHR.bin")

        if f6 & 0x02:
            NRAM = header[8]
            if NRAM == 0:
                NRAM = 1
            ram_sz = NRAM*8192
            print(f"PRG-RAM size: {ram_sz} ({NRAM}x 8k blocks)")

        if f6 & 0x04:
            print("contains trainer")

        if f6 & 0x08:
            print("4-screen mirroring")
        else:
            if f6 & 0x01:
                print("V mirroring")
            else:
                print("H mirroring")


        mapper = (f7 & 0xf0) + (f6 >> 4)
        if mapper == 0:
            print("no mapper")
        else:
            print(f"mapper {mapper}")




if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert NES file to memory config files.")
    parser.add_argument("nes_file", help="Path to the nes file")

    args = parser.parse_args()
    nes_file = args.nes_file

    try:
        nes2mem(nes_file)
        print("Conversion complete.")
    except FileNotFoundError:
        print("Error: Input file not found.")
    except Exception as e:
        print(f"An error occurred: {e}")
