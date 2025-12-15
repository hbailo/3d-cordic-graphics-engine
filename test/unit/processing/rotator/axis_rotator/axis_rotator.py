import math as m
import numpy as np
from math import sqrt

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

        (xi, yi, zi) = (xo, yo, zo)
        
    Kn = compute_K(iters)

    xo = Kn * xo
    yo = Kn * yo

    return xo, yo, zo

def rot(xi, yi, zi, axis, angle):
    c = m.cos(angle)
    s = m.sin(angle)

    xo = 0
    yo = 0
    zo = 0
  
    match axis:
        case 'x':
            xo = xi
            yo = c * yi - s * zi
            zo = s * yi + c * zi
            
        case 'y':
            xo = c * xi + s * zi
            yo = yi
            zo = -s * xi + c * zi
            
        case 'z':
            xo = c * xi - s * yi
            yo = s * xi + c * yi
            zo = zi

        case _:
            raise ValueError("Axis must be 'x', 'y' or 'z'")
        
    return xo, yo, zo

def evaluate(idx, xi, yi, zi, axis, angle, DATA_WIDTH, ITERS):
    print("===========================================================")
    print(f"Case {idx}")
    print(f"Axis {axis}")
    
    xoc = 0
    yoc = 0
    zoc = 0
    
    match axis:
        case 'x':
            xoc         =  xi
            yoc, zoc, _ = cordic(yi, zi, angle, DATA_WIDTH, ITERS)
            
        case 'y':
            yoc         = yi
            zoc, xoc, _ = cordic(zi, xi, angle, DATA_WIDTH, ITERS)
  
        case 'z':
            zoc         = zi
            xoc, yoc, _ = cordic(xi, yi, angle, DATA_WIDTH, ITERS)
        
        case _:
            raise ValueError("Axis must be 'x', 'y' or 'z'")

    angle_rad = angle * np.pi / 2**(DATA_WIDTH - 1)
    angle_deg = angle * 180   / 2**(DATA_WIDTH - 1)
    
    xom, yom, zom = rot(xi, yi, zi, axis, angle_rad)
    
    print(f"Angle  : {angle} = {angle_deg :.1f}º")
    print(f"Input  : (xi, yi, zi) = ({xi:6.0f}, {yi:6.0f}, {zi:6.0f})")
    print(f"Cordic : (xo, yo, zo) = ({xoc:6.1f}, {yoc:6.1f}, {zoc:6.1f})")
    print(f"Math   : (xo, yo, zo) = ({xom:6.1f}, {yom:6.1f}, {zom:6.1f})")
    
# Evaluation
DATA_WIDTH = 9
ITERS      = DATA_WIDTH - 2

# Case 1
xi    = 99
yi    = -33
zi    = 214
angle = -2**(DATA_WIDTH - 2) + 31
axis  = 'x'

evaluate(1, xi, yi, zi, axis, angle, DATA_WIDTH, ITERS)

# Case 2
xi    = 99
yi    = -33
zi    = 214
angle = -2**(DATA_WIDTH - 2) + 31
axis  = 'y'

evaluate(2, xi, yi, zi, axis, angle, DATA_WIDTH, ITERS)

# Case 3
xi    =  99
yi    = -33
zi    = 214
angle = -2**(DATA_WIDTH - 2) + 31
axis  = 'z'

evaluate(3, xi, yi, zi, axis, angle, DATA_WIDTH, ITERS)
