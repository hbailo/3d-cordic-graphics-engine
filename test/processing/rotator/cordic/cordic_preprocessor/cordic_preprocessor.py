import numpy as np

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

# Evaluation
DATA_WIDTH = 9

## Case 1
xi = 99
yi = -33
zi = 0

xo, yo, zo = cordic_preprocessor(xi, yi, zi, DATA_WIDTH)

print(f"(xi, yi) = ({xi}, {yi}) | zi = {zi}")
print(f"(xo, yo) = ({xo:.1f}, {yo:.1f}) | zo = {zo}")

## Case 2
zi = 2**(DATA_WIDTH - 2)

xo, yo, zo = cordic_preprocessor(xi, yi, zi, DATA_WIDTH)

print(f"(xi, yi) = ({xi}, {yi}) | zi = {zi}")
print(f"(xo, yo) = ({xo:.1f}, {yo:.1f}) | zo = {zo}")

## Case 3
zi = 3 * 2**(DATA_WIDTH - 3)

xo, yo, zo = cordic_preprocessor(xi, yi, zi, DATA_WIDTH)

print(f"(xi, yi) = ({xi}, {yi}) | zi = {zi}")
print(f"(xo, yo) = ({xo:.1f}, {yo:.1f}) | zo = {zo}")

## Case 4
zi = -3 * 2**(DATA_WIDTH - 3)

xo, yo, zo = cordic_preprocessor(xi, yi, zi, DATA_WIDTH)

print(f"(xi, yi) = ({xi}, {yi}) | zi = {zi}")
print(f"(xo, yo) = ({xo:.1f}, {yo:.1f}) | zo = {zo}")

## Case 5
zi = -2**(DATA_WIDTH - 1)

xo, yo, zo = cordic_preprocessor(xi, yi, zi, DATA_WIDTH)

print(f"(xi, yi) = ({xi}, {yi}) | zi = {zi}")
print(f"(xo, yo) = ({xo:.1f}, {yo:.1f}) | zo = {zo}")
