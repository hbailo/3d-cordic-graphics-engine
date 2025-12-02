import numpy as np

def round_as_vhdl(x):
    """Round half up"""
    return int(x + 0.5) if x >= 0 else int(x - 0.5)

def cordic_stage(xi, yi, zi, iters, i):
    ei = round_as_vhdl(2**(iters + 1) / np.pi * np.arctan(2**(-i)))
    
    di = 1 if zi >= 0 else -1
 
    xo = xi - di * np.right_shift(yi, i)
    yo = yi + di * np.right_shift(xi, i)
    zo = zi - di * ei

    print(f"Stage {i} | {ei=} | {xi=} | {yi=} | {zi=} | {xo=} | {yo=} | {zo=}")
    
    return xo, yo, zo

# Evaluation
DATA_WIDTH = 9
ITERS      = DATA_WIDTH - 2
I          = ITERS - 1

# Case 1
xi = 99
yi = -33
zi = 2**(DATA_WIDTH - 3)

cordic_stage(xi, yi, zi, ITERS, I)
