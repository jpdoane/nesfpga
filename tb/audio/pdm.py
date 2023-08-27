#!/bin/python3

import numpy as np
import matplotlib.pyplot as plt

def pdm(x, m):
    n = len(x)
    y = np.zeros(n)
    error = np.zeros(n+1)    
    for i in range(n):
        y[i] = m if x[i] > error[i] else 0
        error[i+1] = y[i] - x[i] + error[i]
    return y, error[0:n]


def pdm_fixed(x,m):
    n = len(x)
    y = np.zeros(n)
    error = np.zeros(n+1).astype(int)
    for i in range(n):
        delta = error[i] - x[i]
        if delta<0:            
            y[i] = m
            error[i+1] = (delta.astype(int)-1) & 0xff
        else:
            y[i] = 0
            error[i+1] = delta.astype(int) & 0xff
    return y, error[0:n]


n = 100
fclk = 250e6 # clock frequency (Hz)
t = np.arange(n) / fclk
f_sin = 5e6 # sine frequency (Hz)

x = np.rint(127 + 120 * np.sin(2*np.pi*f_sin*t)).astype(int)
y, error = pdm(x,255)
y2, error2 = pdm_fixed(x,255)

plt.plot(1e9*t, x, label='input signal')
plt.step(1e9*t, y, label='pdm signal',  linewidth=2.0)
plt.step(1e9*t, error, label='error')
plt.step(1e9*t, y2, label='pdm signal2',  linewidth=2.0)
plt.step(1e9*t, error2, label='error2')
plt.xlabel('Time (ns)')
plt.ylim(-5,260)
plt.legend()
plt.show()