from matplotlib import pyplot as plt
from matplotlib import ticker as ticker
import numpy as np

# Screen size
WIDTH_PX  = 320
HEIGHT_PX = 320

fig, (ax1, ax2) = plt.subplots(1, 2)

# Plot raw
x, y, z = np.loadtxt("data/coordinates.csv", delimiter=",", skiprows=1, unpack=True)

ax1.plot(y, z, 's', markersize=0.5, color="white")


ax1.set_title("Raw", y=1.07)
ax1.set_xlim(-1.0, 1.0)
ax1.set_ylim(-1.0, 1.0)
ax1.set_aspect('equal', adjustable='box')
ax1.set_facecolor('black')

# Plot bitmap
# Map [-1, 1] to [0, WIDTH_PX - 1] and [0, HEIGHT_PX - 1]
x_scaled  = (1 + y) * (WIDTH_PX  - 1) / 2
y_scaled  = (1 - z) * (HEIGHT_PX - 1) / 2

x_px = x_scaled.astype(int)
y_px = y_scaled.astype(int)

img = np.zeros((HEIGHT_PX, WIDTH_PX), dtype=np.uint8)
img[y_px, x_px] = 255

ax2.imshow(img, cmap="gray")

ax2.set_title(f"{WIDTH_PX} x {HEIGHT_PX}", y=1.07)
ax2.xaxis.tick_top()
ax2.xaxis.set_major_locator(ticker.MaxNLocator(integer=True))
ax2.yaxis.set_major_locator(ticker.MaxNLocator(integer=True))

plt.show()
