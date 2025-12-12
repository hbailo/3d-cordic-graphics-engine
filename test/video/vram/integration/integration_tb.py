from matplotlib import pyplot as plt
from matplotlib import ticker as ticker
import numpy as np

# Screen size
WIDTH_PX  = 320
HEIGHT_PX = 320

# Quantization
DATA_WIDTH = 9
F          = DATA_WIDTH - 1
ONE        = np.int64(2**F)

# Plot
fig, (ax1, ax2) = plt.subplots(1, 2)
fig.suptitle(f"{WIDTH_PX} x {HEIGHT_PX}")

# Load raw CSV
x, y, z = np.loadtxt(f"../../../resources/data/q0.{F}-coordinates.csv", delimiter=",", dtype=np.int64, skiprows=1, unpack=True)

# Map [-1, 1) to [0, WIDTH_PX - 1] and [0, HEIGHT_PX - 1]
x_scaled  = (ONE + y) * np.int64(WIDTH_PX / 2)
y_scaled  = (ONE - z) * np.int64(HEIGHT_PX / 2) - 1

x_px = x_scaled >> F
y_px = y_scaled >> F

px_addr = y_px * WIDTH_PX + x_px

# Build image
img1 = np.zeros((HEIGHT_PX, WIDTH_PX), dtype=np.uint8)
img1[y_px, x_px] = 255

ax1.imshow(img1, cmap="gray")

ax1.set_title(f"VRAM Load", y=1.07)
ax1.xaxis.tick_top()
ax1.xaxis.set_major_locator(ticker.MaxNLocator(integer=True))
ax1.yaxis.set_major_locator(ticker.MaxNLocator(integer=True))

# Load raw CSV
img2 = np.loadtxt("vram_dump.txt", dtype=np.uint64)

img2[img2 == 1] = 255

ax2.imshow(img2, cmap="gray")

ax2.set_title(f"VRAM Dump", y=1.07)
ax2.xaxis.tick_top()
ax2.xaxis.set_major_locator(ticker.MaxNLocator(integer=True))
ax2.yaxis.set_major_locator(ticker.MaxNLocator(integer=True))

assert np.all(img1 == img2)

plt.show()
