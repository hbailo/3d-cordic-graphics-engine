from matplotlib import pyplot as plt
from matplotlib import ticker as ticker
import math as m
import numpy as np

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

def xyz_rot_int(xi, yi, zi, angle_x_rad, angle_y_rad, angle_z_rad):
    xom_rot_x, yom_rot_x, zom_rot_x    = rot(xi, yi, zi, 'x', angle_x_rad)
    xom_rox_xy, yom_rot_xy, zom_rot_xy = rot(xom_rot_x, yom_rot_x, zom_rot_x, 'y', angle_y_rad)
    xom, yom, zom = rot(xom_rox_xy, yom_rot_xy, zom_rot_xy, 'z', angle_z_rad)

    return np.int64(xom), np.int64(yom), np.int64(zom)

def xyz_rot_float(xi, yi, zi, angle_x_rad, angle_y_rad, angle_z_rad):
    xom_rot_x, yom_rot_x, zom_rot_x    = rot(xi, yi, zi, 'x', angle_x_rad)
    xom_rox_xy, yom_rot_xy, zom_rot_xy = rot(xom_rot_x, yom_rot_x, zom_rot_x, 'y', angle_y_rad)
    xom, yom, zom = rot(xom_rox_xy, yom_rot_xy, zom_rot_xy, 'z', angle_z_rad)

    return xom, yom, zom

# Quantization
DATA_WIDTH = 9
F          = DATA_WIDTH - 1
ONE        = np.int64(2**F)

# Rotation angles
angle_x = 0
angle_y = 0
angle_z = 0
angle_x_rad = angle_x * np.pi / 2**(DATA_WIDTH - 1)
angle_y_rad = angle_y * np.pi / 2**(DATA_WIDTH - 1)
angle_z_rad = angle_z * np.pi / 2**(DATA_WIDTH - 1)

# Screen size
WIDTH_PX  = 320
HEIGHT_PX = 320

# Process
x, y, z = np.loadtxt(f"../../../resources/data/q0.{F}-coordinates.csv", delimiter=",", dtype=np.int64, skiprows=1, unpack=True)

x, y, z = xyz_rot_int(x, y, z, angle_x_rad, angle_y_rad, angle_z_rad)

# Map [-1, 1) to [0, WIDTH_PX - 1] and [0, HEIGHT_PX - 1]
x_scaled  = (ONE + y) * np.int64(WIDTH_PX / 2)
y_scaled  = (ONE - z) * np.int64(HEIGHT_PX / 2) - 1

x_px = x_scaled >> F
y_px = y_scaled >> F

# Build image
img = np.zeros((HEIGHT_PX, WIDTH_PX), dtype=np.uint8)
img[y_px, x_px] = 255

plt.figure()
plt.imshow(img, cmap="gray")

plt.gca().xaxis.tick_top()
plt.gca().xaxis.set_major_locator(ticker.MaxNLocator(integer=True))
plt.gca().yaxis.set_major_locator(ticker.MaxNLocator(integer=True))
plt.show()
