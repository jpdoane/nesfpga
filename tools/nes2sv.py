#!/usr/bin/python3

import argparse, os
import argparse
import numpy as np

def nes2sv(nes_file, mem_file, sv_file):
    with open(nes_file, 'rb') as fnes:
        data = fnes.read()

        with open(sv_file, 'w') as f_sv:
            f_sv.write("`define NES_MEM_FILE \"%s\"\n" % mem_file)
            header64 = ''.join(format(x, '02x') for x in reversed(data[4:12]))
            f_sv.write("`define NES_HEADER 64\'h%s\n" % header64)
            PRG_START = 16
            PRG_STOP = PRG_START + data[4]*4096 - 1 #each 16kB chunk is 4k 32b words 
            CHR_START = PRG_STOP+1
            CHR_STOP = CHR_START + data[5]*2048 - 1 #each 8kB chunk is 2k 32b words 
            f_sv.write("`define PRG_START %d\n" %   PRG_START)
            f_sv.write("`define PRG_STOP %d\n"  %  PRG_STOP)
            f_sv.write("`define CHR_START %d\n" % CHR_START)
            f_sv.write("`define CHR_STOP %d\n"  %  CHR_STOP)

        data32 = np.frombuffer(data, dtype=np.dtype('<u4'))
        with open(mem_file, 'w') as f_mem:
            f_mem.write("@0000\n")
            for word in data32:
                hex_repr = "{:08x}\n".format(word)
                f_mem.write(hex_repr)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert NES file to memory config files.")
    parser.add_argument("nes_file", help="Path to the nes file")
    parser.add_argument("sv_file", help="Path to the sv file", nargs='?', default="cart_incl.sv")
    parser.add_argument("mem_file", help="Path to the mem file", nargs='?', default="cart.mem")

    args = parser.parse_args()

    try:
        nes2sv(args.nes_file,  args.mem_file, args.sv_file)
        print("Conversion complete.")
    except FileNotFoundError:
        print("Error: Input file not found.")
    except Exception as e:
        print(f"An error occurred: {e}")
