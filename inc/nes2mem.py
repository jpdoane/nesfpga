#!/usr/bin/python3

import argparse, os
import argparse

def writemem(data, memfile):
    with open(memfile, 'w') as f_mem:
        f_mem.write("@0000\n")
        for byte in data:
            hex_repr = "{:02x}\n".format(byte)
            f_mem.write(hex_repr)

def nes2mem(nes_file):
    with open(nes_file, 'rb') as fnes:
        header = fnes.read(16)
        writemem(header, "NESheader.mem")

        flags = header[6]
        if flags & 0x4:
            TRAIN = fnes.read(512)
            writemem(TRAIN, "TRAIN.mem")            

        NPRG = header[4]
        PRG = fnes.read(NPRG * 16384)
        if NPRG == 1:
            PRG = PRG+PRG #fill 16kb
        elif NPRG != 2:
            raise Exception("PRG size of {} B is not supported. Must be either 8kB or 16kB".format(NPRG*16384))                
        writemem(PRG, "PRG.mem")

        NCHR = header[5]
        CHR = fnes.read(NCHR*8192)
        if NCHR != 1:
            raise Exception("CHR size of {} B is not supported. Must be 8kB".format(NCHR*8192))                
        writemem(CHR, "CHR.mem")


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
