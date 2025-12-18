import numpy as np

DATA_POINTS = 100
DATA_WIDTH  = 9
F           = DATA_WIDTH - 1

loaded = np.loadtxt(f"../../resources/data/q0.{F}-coordinates.csv", delimiter=",", dtype=np.int64, skiprows=1)

dumped = np.loadtxt(f"./build/ram_dump.txt", delimiter=",", dtype=np.int64, skiprows=1)

assert np.all(loaded[:DATA_POINTS] == dumped[:DATA_POINTS])
