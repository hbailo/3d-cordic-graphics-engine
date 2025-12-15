import math as m
import numpy as np
from math import sqrt

def rot(x, y, angle):
  c = m.cos(angle)
  s = m.sin(angle)

  xo = c * xi - s * yi
  yo = s * xi + c * yi
  
  return xo, yo

def cordic_preprocessor(xi, yi, zi, data_width):
    """
    Performs CORDIC angle range reduction from [-pi, pi] to [-pi/2, pi/2].
    """
    PI_OVER_2 = 2**(data_width - 2)
    NEG_PI    = -2**(data_width - 1)

    if zi < -PI_OVER_2 or zi > PI_OVER_2:
        xo = -xi
        yo = -yi
    else:
        xo = xi
        yo = yi
        
    if zi < -PI_OVER_2:
        zo = zi - NEG_PI    
    elif zi > PI_OVER_2:
        zo = zi + NEG_PI        
    else:
        zo = zi

    return xo, yo, zo

def compute_K(iters):
    """
    Compute K(n) for n = iters.
    """
    k = 1.0
    
    for i in range(iters):
        k *= 1 / sqrt(1 + 2 ** (-2 * i))
        
    return k

def round_as_vhdl(x):
    """Round half up"""
    return int(x + 0.5) if x >= 0 else int(x - 0.5)

def cordic_stage(i, ei, xi, yi, zi):
    di = 1 if zi >= 0 else -1
 
    xo = xi - di * np.right_shift(yi, i)
    yo = yi + di * np.right_shift(xi, i)
    zo = zi - di * ei

    return xo, yo, zo

def cordic(x, y, z, data_width, iters):
    (xi, yi, zi) = cordic_preprocessor(x, y, z, data_width)
    
    for i in range(iters):
        ei = round_as_vhdl(2**(iters + 1) / np.pi * np.arctan(2**(-i)))

        xo, yo, zo = cordic_stage(i, ei, xi, yi, zi)

        print(f"Stage {i} | {ei=} | {xi=} | {yi=} | {zi=} | {xo=} | {yo=} | {zo=}")
        
        (xi, yi, zi) = (xo, yo, zo)
        
    Kn = compute_K(iters)

    xo = Kn * xo
    yo = Kn * yo

    return xo, yo, zo

# Evaluation
DATA_WIDTH = 9
ITERS      = DATA_WIDTH - 2

## Case 1
xi = 99
yi = -33
zi = -2**(DATA_WIDTH - 2) + 31

print("================================")
print("Case 1")
print(f"(xi, yi, zi) = ({xi}, {yi}, {zi})")

xo, yo, zo = cordic(xi, yi, zi, DATA_WIDTH, ITERS)

print(f"Cordic: (xo, yo, zo) = ({xo:.1f}, {yo:.1f}, {zo})")

zi_rad = zi * np.pi / 2**(DATA_WIDTH - 1)
zi_deg = zi * 180   /  2**(DATA_WIDTH - 1)

xo, yo = rot(xi, yi, zi_rad)

print(f"Math: (xo, yo) = ({xo:.1f}, {yo:.1f}) | zi_deg = {zi_deg}")

## Case 3
xi = 128
yi = -128
zi = -2**(DATA_WIDTH - 1)

print("================================")
print("Case 3")
print(f"(xi, yi, zi) = ({xi}, {yi}, {zi})")

xo, yo, zo = cordic(xi, yi, zi, DATA_WIDTH, ITERS)

print(f"Cordic: (xo, yo, zo) = ({xo:.1f}, {yo:.1f}, {zo})")

zi_rad = zi * np.pi / 2**(DATA_WIDTH - 1)
zi_deg = zi * 180   /  2**(DATA_WIDTH - 1)

xo, yo = rot(xi, yi, zi_rad)

print(f"Math: (xo, yo) = ({xo:.1f}, {yo:.1f}) | zi_deg = {zi_deg}")

## Case 5
xi = 0
yi = 0
zi = 0

print("================================")
print("Case 5")
print(f"(xi, yi, zi) = ({xi}, {yi}, {zi})")

xo, yo, zo = cordic(xi, yi, zi, DATA_WIDTH, ITERS)

print(f"Cordic: (xo, yo, zo) = ({xo:.1f}, {yo:.1f}, {zo})")

zi_rad = zi * np.pi / 2**(DATA_WIDTH - 1)
zi_deg = zi * 180   /  2**(DATA_WIDTH - 1)

xo, yo = rot(xi, yi, zi_rad)

print(f"Math: (xo, yo) = ({xo:.1f}, {yo:.1f}) | zi_deg = {zi_deg}")
