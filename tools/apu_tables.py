#!/usr/bin/python3

import argparse, os
import argparse

def writemem(data, memfile):
    with open(memfile, 'w') as f_mem:
        f_mem.write("@0000\n")
        for byte in data:
            hex_repr = "{:04x}\n".format(byte)
            f_mem.write(hex_repr)



pulse_table=[]
for n in range(0,30):
    v = 0 if n==0 else round(65535 * 95.52 / (8128.0 / n + 100))
    pulse_table.append(v)
writemem(pulse_table, "pulse_table.mem")

tnd_table=[]
for n in range(0,202):
    v = 0 if n==0 else round(65535 * 163.67 / (24329.0 / n + 100))
    tnd_table.append(v)
writemem(tnd_table, "tnd_table.mem")
