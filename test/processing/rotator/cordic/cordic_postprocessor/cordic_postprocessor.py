from math import sqrt

def compute_K(iters):
    """
    Compute K(n) for n = iters.
    """
    k = 1.0
    
    for i in range(iters):
        k *= 1 / sqrt(1 + 2 ** (-2 * i))
    return k

# Evaluate
DATA_WIDTH = 9
ITERS      = DATA_WIDTH - 2

xi = 99
yi = -33

kn = compute_K(ITERS)

xo = kn * xi
yo = kn * yi

print(f"(xi, yi) = ({xi}, {yi})")
print(f"kn = {kn} | (xo, yo) = ({xo}, {yo})")
