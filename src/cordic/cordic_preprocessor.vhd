--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief CORDIC angle preprocessor for full [-π, π] range
--! @details 
--! This module performs angle range reduction for CORDIC algorithm, mapping
--! input angles from [-π, π] range to [-π/2, π/2] range while preserving
--! the original rotation through coordinate adjustments.
--!
--! Number formats:
--! - Coordinates (x, y): Signed integers in two's complement format
--!   - Format: 1 sign bit + (N+1) magnitude bits
--!   - Numerical range: [-2^(N+1), 2^(N+1) - 1]
--!
--! - Angles (z): Fixed-point scaled radians in Q0.(N+1) format
--!   - Format: 1 sign bit + 0 integer bits + (N+1) fractional bits
--!   - Numerical range: [-π, π) where π = 2^(N+1)
--!   - Resolution: π / 2^(N+1) radians per LSB
--!   - Encoding: z_actual = z_encoded * (π / 2^(N + 1))
entity cordic_preprocessor is
  generic (
    --! @brief Total number of CORDIC iterations in the pipeline    
    N: positive range 1 to 1023
  );
  
  port (
    --! @brief Initial x-coordinate before rotation (signed integer)
    --! @details Range: [-2^(N+1), 2^(N+1) - 1]
    xi: in std_logic_vector(N + 1 downto 0);

    --! @brief Initial y-coordinate before rotation (signed integer)
    --! @details Range: [-2^(N+1), 2^(N+1) - 1]
    yi: in std_logic_vector(N + 1 downto 0);
    
    --! @brief Initial rotation angle  (Q0.(N+1) format)
    --! @details Scaled radians: actual angle = zi × (π/2^(N+1))
    zi: in std_logic_vector(N + 1 downto 0);

    --! @brief Adjusted x-coordinate after angle quadrant adjustment (signed integer)
    xo: out std_logic_vector(N + 1 downto 0);

    --! @brief Adjusted y-coordinate after angle quadrant adjustment (signed integer)
    yo: out std_logic_vector(N + 1 downto 0);

    --! @brief Reduced rotation angle after quadrant adjustment (Q0.(N+1) format)
    zo: out std_logic_vector(N + 1 downto 0)
  );
end entity cordic_preprocessor;

--! @brief Dataflow architecture of the angle range reduction
--! @details
--! The architecture performs the following operations:
--! 1. Detects whether the input angle lies outside the CORDIC-compatible range [-π/2, π/2].
--! 2. If so, shifts the angle by ±π to bring it into the valid range and simultaneously negates both input coordinates to preserve the direction of rotation.
architecture dataflow of cordic_preprocessor is
  
  --! @brief π/2 constant in Q0.(N+1) format
  constant PI_OVER_2: signed(N + 1 downto 0) := to_signed(2**N, N + 2);

  --! @brief -π constant in Q0.(N+1) format 
  constant NEG_PI: signed(N + 1 downto 0) := to_signed(-2**(N + 1), N + 2); 

  -- Internal signed versions of inputs
  signal xi_s: signed(xi'range);  --! Signed version of xi input
  signal yi_s: signed(yi'range);  --! Signed version of yi input
  signal zi_s: signed(zi'range);  --! Signed version of zi input

  -- Internal signed versions of outputs
  signal xo_s: signed(xo'range);  --! Signed version of xo output 
  signal yo_s: signed(yo'range);  --! Signed version of yo output 
  signal zo_s: signed(zo'range);  --! Signed version of zo output
    
begin

  -- Input type conversion
  xi_s <= signed(xi);
  yi_s <= signed(yi);
  zi_s <= signed(zi);

  -- Coordinate adjustment
  xo_s <= -xi_s when (zi_s < -PI_OVER_2 or zi_s > PI_OVER_2) else
           xi_s;

  yo_s <= -yi_s when (zi_s < -PI_OVER_2 or zi_s > PI_OVER_2) else
           yi_s;

  -- Angle range reduction  
  zo_s <= zi_s - NEG_PI when zi_s < -PI_OVER_2 else
          zi_s + NEG_PI when zi_s >  PI_OVER_2 else
          zi_s;

  -- Output type conversion
  xo <= std_logic_vector(xo_s);
  yo <= std_logic_vector(yo_s);
  zo <= std_logic_vector(zo_s);  
  
end architecture dataflow;
