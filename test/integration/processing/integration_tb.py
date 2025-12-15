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

def xyz_rot(xi, yi, zi, angle_x_rad, angle_y_rad, angle_z_rad):
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
angle_x = 143
angle_y = -12
angle_z = -197
angle_x_rad = angle_x * np.pi / 2**(DATA_WIDTH - 1)
angle_y_rad = angle_y * np.pi / 2**(DATA_WIDTH - 1)
angle_z_rad = angle_z * np.pi / 2**(DATA_WIDTH - 1)

# Screen size
WIDTH_PX  = 320
HEIGHT_PX = 320

# Load raw CSV
x, y, z = np.loadtxt(f"../../resources/data/coordinates.csv", delimiter=",", skiprows=1, unpack=True)

plt.figure()
x, y, z = xyz_rot_float(x, y, z, angle_x_rad, angle_y_rad, angle_z_rad)
plt.plot(y, z, 's', markersize='0.5', color="white")
plt.title("Math rotation")
plt.gca().set_xlim(-1.0, 1.0)
plt.gca().set_ylim(-1.0, 1.0)
plt.gca().set_aspect('equal', adjustable='box')
plt.gca().set_facecolor('black')

# Plot
fig, (ax1, ax2) = plt.subplots(1, 2)
fig.suptitle(f"{WIDTH_PX} x {HEIGHT_PX} - Q0.{F}")

# Load raw CSV
x, y, z = np.loadtxt(f"../../resources/data/q0.{F}-coordinates.csv", delimiter=",", dtype=np.int64, skiprows=1, unpack=True)

x, y, z = xyz_rot(x, y, z, angle_x_rad, angle_y_rad, angle_z_rad)

# Map [-1, 1) to [0, WIDTH_PX - 1] and [0, HEIGHT_PX - 1]
x_scaled  = (ONE + y) * np.int64(WIDTH_PX / 2)
y_scaled  = (ONE - z) * np.int64(HEIGHT_PX / 2) - 1

x_px = x_scaled >> F
y_px = y_scaled >> F

# Build image
img1 = np.zeros((HEIGHT_PX, WIDTH_PX), dtype=np.uint8)
img1[y_px, x_px] = 255

ax1.imshow(img1, cmap="gray")

ax1.set_title(f"Math rotation", y=1.07)
ax1.xaxis.tick_top()
ax1.xaxis.set_major_locator(ticker.MaxNLocator(integer=True))
ax1.yaxis.set_major_locator(ticker.MaxNLocator(integer=True))

# Load cordic rot result
x, y, z = np.loadtxt(f"build/rot.txt", delimiter=",", dtype=np.int64, unpack=True)

# Map [-1, 1) to [0, WIDTH_PX - 1] and [0, HEIGHT_PX - 1]
x_scaled  = (ONE + y) * np.int64(WIDTH_PX / 2)
y_scaled  = (ONE - z) * np.int64(HEIGHT_PX / 2) - 1

x_px = x_scaled >> F
y_px = y_scaled >> F

img2 = np.zeros((HEIGHT_PX, WIDTH_PX), dtype=np.uint8)
img2[y_px, x_px] = 255

ax2.imshow(img2, cmap="gray")

ax2.set_title(f"CORDIC rotation", y=1.07)
ax2.xaxis.tick_top()
ax2.xaxis.set_major_locator(ticker.MaxNLocator(integer=True))
ax2.yaxis.set_major_locator(ticker.MaxNLocator(integer=True))

plt.show()
