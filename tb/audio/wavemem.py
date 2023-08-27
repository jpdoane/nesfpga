#!/bin/python3

import numpy as np
import matplotlib.pyplot as plt
import os

def writemem(data, memfile):
    with open(memfile, 'w') as f_mem:
        f_mem.write("@0000\n")
        for byte in data:
            hex_repr = "{:02x}\n".format(byte)
            f_mem.write(hex_repr)

N = 256
t = np.arange(N)/N
x = np.rint(127 + 120 * np.sin(2*np.pi*t)).astype(int)
writemem(x, "wave.mem")
