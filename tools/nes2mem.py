#!/usr/bin/python3

import argparse, os
import argparse
import numpy as np

def writemem(data, memfile):
    data32 = np.frombuffer(data, dtype=np.dtype('<u4'))
    with open(memfile, 'w') as f_mem:
        f_mem.write("@0000\n")
        for word in data32:
            hex_repr = "{:08x}\n".format(word)
            f_mem.write(hex_repr)

def nes2mem(nes_file, sv_file, sav_file):

    if len(sav_file) > 0:
        with open(sav_file, 'rb') as fsav:
            SAV = fsav.read()
            writemem(SAV, "SAV.mem")

    with open(nes_file, 'rb') as fnes:
        header = fnes.read(16)
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

        NCHR = header[5]
        if NCHR == 0:
            print("uses CHR RAM...")
        else:
            chr_sz = NCHR * 8192
            CHR = fnes.read(chr_sz)
            print(f"CHR size: {chr_sz} ({NCHR}x 8k blocks)")
            writemem(CHR, "CHR.mem")

        with open(sv_file, 'w') as f_sv:
            header64 = ''.join(format(x, '02x') for x in reversed(header[4:12]))
            f_sv.write("`define NES_HEADER 64\'h%s\n" % header64)
            f_sv.write("`define NES_PRG_FILE \"%s\"\n" % os.path.abspath("PRG.mem"))
            f_sv.write("`define NES_CHR_FILE \"%s\"\n" % os.path.abspath("CHR.mem"))
            if len(sav_file) > 0:
                f_sv.write("`define NES_SAV_FILE \"%s\"\n" % os.path.abspath("SAV.mem"))
            else:
                f_sv.write("`define NES_SAV_FILE \"\"\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert NES file to memory config files.")
    parser.add_argument("nes_file", help="Path to the nes file")
    parser.add_argument("sv_file", help="Path to the sv file", nargs='?', default="cart_incl.sv")
    parser.add_argument("sav_file", help="Path to the sav file", nargs='?', default="")

    args = parser.parse_args()

    try:
        nes2mem(args.nes_file,  args.sv_file,  args.sav_file)
        print("Conversion complete.")
    except FileNotFoundError:
        print("Error: Input file not found.")
    except Exception as e:
        print(f"An error occurred: {e}")
