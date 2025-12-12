import numpy as np

def quantize(x, F):
    """Converts value x to signed Q0.F fixed point representation."""
    x = np.clip(x, -1.0, 1.0 - 2**(-F))
    
    scale  = 1 << F
    scaled = x * scale
    
    return scaled.astype(np.int64)

input_filename = "data/coordinates.csv"

points = np.loadtxt("data/coordinates.csv", delimiter=",", skiprows=1)

DATA_WIDTH = 9
F          = DATA_WIDTH - 1

quantized_points = quantize(points, F)
output_filename = f"data/q0.{F}-coordinates.csv"

np.savetxt(output_filename, quantized_points, delimiter=",", fmt="%d", header="x,y,z", comments="")
