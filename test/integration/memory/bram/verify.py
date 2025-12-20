import numpy as np

DATA_WIDTH = 9
F          = DATA_WIDTH - 1

BASE_PATH = "../../../.."
loaded = np.loadtxt(f"{BASE_PATH}/test/resources/data/q0.{F}-coordinates.csv", delimiter=",", dtype=np.int64, skiprows=1)

dumped = np.loadtxt(f"./build/ram_dump.csv", delimiter=",", dtype=np.int64, skiprows=1)

assert np.all(loaded == dumped)
