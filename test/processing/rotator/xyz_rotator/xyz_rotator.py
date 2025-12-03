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

def evaluate(idx, xi, yi, zi, angle_x, angle_y, angle_z, DATA_WIDTH, ITERS):
    print("===========================================================")
    print(f"Case {idx}")

    # Cordic rotation
    xoc_rot_x =  xi
    yoc_rot_x, zoc_rot_x, _ = cordic(yi, zi, angle_x, DATA_WIDTH, ITERS)
    
    yoc_rot_xy = yoc_rot_x
    zoc_rot_xy, xoc_rot_xy, _ = cordic(int(zoc_rot_x), int(xoc_rot_x), angle_y, DATA_WIDTH, ITERS)
  
    zoc         = zoc_rot_xy
    xoc, yoc, _ = cordic(int(xoc_rot_xy), int(yoc_rot_xy), angle_z, DATA_WIDTH, ITERS)

    # Math rotation    
    angle_x_rad = angle_x * np.pi / 2**(DATA_WIDTH - 1)
    angle_x_deg = angle_x * 180   / 2**(DATA_WIDTH - 1)

    angle_y_rad = angle_y * np.pi / 2**(DATA_WIDTH - 1)
    angle_y_deg = angle_y * 180   / 2**(DATA_WIDTH - 1)

    angle_z_rad = angle_z * np.pi / 2**(DATA_WIDTH - 1)
    angle_z_deg = angle_z * 180   / 2**(DATA_WIDTH - 1)

    xom_rot_x, yom_rot_x, zom_rot_x    = rot(xi, yi, zi, 'x', angle_x_rad)
    xom_rox_xy, yom_rot_xy, zom_rot_xy = rot(xom_rot_x, yom_rot_x, zom_rot_x, 'y', angle_y_rad)
    xom, yom, zom = rot(xom_rox_xy, yom_rot_xy, zom_rot_xy, 'z', angle_z_rad)
    
    print(f"Angle x        : {angle_x} = {angle_x_deg :.1f}º")
    print(f"Angle y        : {angle_y} = {angle_y_deg :.1f}º")
    print(f"Angle z        : {angle_z} = {angle_z_deg :.1f}º")        
    print(f"Input          : (xi, yi, zi) = ({xi:6.0f}, {yi:6.0f}, {zi:6.0f})")
    print(f"Cordic rot x   : (xo, yo, zo) = ({xoc_rot_x:6.1f}, {yoc_rot_x:6.1f}, {zoc_rot_x:6.1f})")
    print(f"Cordic rot xy  : (xo, yo, zo) = ({xoc_rot_xy:6.1f}, {yoc_rot_xy:6.1f}, {zoc_rot_xy:6.1f})")
    print(f"Cordic rot xyz : (xo, yo, zo) = ({xoc:6.1f}, {yoc:6.1f}, {zoc:6.1f})")        
    print(f"Math           : (xo, yo, zo) = ({xom:6.1f}, {yom:6.1f}, {zom:6.1f})")
    
# Evaluation
DATA_WIDTH = 9
ITERS      = DATA_WIDTH - 2

# Case 1
xi = 99
yi = -33
zi = 214
angle_x = 227
angle_y = 100
angle_z = -21

evaluate(1, xi, yi, zi, angle_x, angle_y, angle_z, DATA_WIDTH, ITERS)

# Case 2
xi = 10
yi = -98
zi = 201
angle_x = 2**(DATA_WIDTH - 3)
angle_y = -2**(DATA_WIDTH - 3)
angle_z = -2**(DATA_WIDTH - 4)

evaluate(2, xi, yi, zi, angle_x, angle_y, angle_z, DATA_WIDTH, ITERS)
