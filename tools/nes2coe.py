#!/usr/bin/python3

import argparse, os
import argparse
import numpy as np

def writecoe(data, coefile):
    try:
        data32 = np.frombuffer(data, dtype=np.dtype('<u4'))
        with open(coefile, 'w') as f_out:
            f_out.write("memory_initialization_radix=16;\n")
            f_out.write("memory_initialization_vector=\n")
            for word in data32:
                hex_repr = "{:08x}".format(word)
                f_out.write(hex_repr)
                f_out.write(",\n")
            f_out.write(";")
    except Exception as e:
        print(f"An error occurred: {e}")


def writemem(data, memfile):
    try:
        data32 = np.frombuffer(data, dtype=np.dtype('<u4'))
        with open(memfile, 'w') as f_out:
            for word in data32:
                hex_repr = "{:08x}\n".format(word)
                f_out.write(hex_repr)
    except Exception as e:
        print(f"An error occurred: {e}")

def nes2mem(nes_file):
    with open(nes_file, 'rb') as fnes:
        header = fnes.read(16)
        writecoe(header, "INES.coe")

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
        writecoe(PRG, "PRG.coe")
        writemem(PRG, "PRG32.mem")

        NCHR = header[5]
        if NCHR == 0:
            print("uses CHR RAM...")
        else:
            chr_sz = NCHR * 8192
            CHR = fnes.read(chr_sz)
            print(f"CHR size: {chr_sz} ({NCHR}x 8k blocks)")
            writecoe(CHR, "CHR.coe")
            writemem(CHR, "CHR32.mem")

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
