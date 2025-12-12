import numpy as np

DATA_WIDTH = 9
F          = DATA_WIDTH - 1

loaded = np.loadtxt(f"../../resources/data/q0.{F}-coordinates.csv", delimiter=",", dtype=np.int64, skiprows=1)

readed = np.loadtxt(f"build/sram_dump.txt", delimiter=",", dtype=np.int64)

assert np.all(loaded == readed)
