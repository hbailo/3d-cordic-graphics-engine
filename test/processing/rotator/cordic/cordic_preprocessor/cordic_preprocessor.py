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
xi     = 99
yi     = -33
zi     = 0
zi_deg = zi * 180   /  2**(DATA_WIDTH - 1)

xo, yo, zo = cordic_preprocessor(xi, yi, zi, DATA_WIDTH)

zo_deg = zo * 180   /  2**(DATA_WIDTH - 1)

print(f"Case 1")
print(f"(xi, yi) = ({xi}, {yi}) | zi = {zi} = {zi_deg:.0f}º")
print(f"(xo, yo) = ({xo:.0f}, {yo:.0f}) | zo = {zo} = {zo_deg :.0f}º")

## Case 2
zi     = 2**(DATA_WIDTH - 2)
zi_deg = zi * 180   /  2**(DATA_WIDTH - 1)

xo, yo, zo = cordic_preprocessor(xi, yi, zi, DATA_WIDTH)

zo_deg = zo * 180   /  2**(DATA_WIDTH - 1)

print(f"Case 2")
print(f"(xi, yi) = ({xi}, {yi}) | zi = {zi} = {zi_deg:.0f}º")
print(f"(xo, yo) = ({xo:.0f}, {yo:.0f}) | zo = {zo} = {zo_deg :.0f}º")

## Case 3
zi     = 3 * 2**(DATA_WIDTH - 3)
zi_deg = zi * 180   /  2**(DATA_WIDTH - 1)

xo, yo, zo = cordic_preprocessor(xi, yi, zi, DATA_WIDTH)

zo_deg = zo * 180   /  2**(DATA_WIDTH - 1)

print(f"Case 3")
print(f"(xi, yi) = ({xi}, {yi}) | zi = {zi} = {zi_deg:.0f}º")
print(f"(xo, yo) = ({xo:.0f}, {yo:.0f}) | zo = {zo} = {zo_deg :.0f}º")

## Case 4
zi     = -3 * 2**(DATA_WIDTH - 3)
zi_deg = zi * 180   /  2**(DATA_WIDTH - 1)

xo, yo, zo = cordic_preprocessor(xi, yi, zi, DATA_WIDTH)

zo_deg = zo * 180   /  2**(DATA_WIDTH - 1)

print(f"Case 4")
print(f"(xi, yi) = ({xi}, {yi}) | zi = {zi} = {zi_deg:.0f}º")
print(f"(xo, yo) = ({xo:.0f}, {yo:.0f}) | zo = {zo} = {zo_deg :.0f}º")

## Case 5
zi     = -2**(DATA_WIDTH - 1)
zi_deg = zi * 180   /  2**(DATA_WIDTH - 1)

xo, yo, zo = cordic_preprocessor(xi, yi, zi, DATA_WIDTH)

zo_deg = zo * 180   /  2**(DATA_WIDTH - 1)

print(f"Case 5")
print(f"(xi, yi) = ({xi}, {yi}) | zi = {zi} = {zi_deg :.0f}º")
print(f"(xo, yo) = ({xo:.0f}, {yo:.0f}) | zo = {zo} = {zo_deg :.0f}º")
