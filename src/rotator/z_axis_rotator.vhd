--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief 3D Rotation around the Z-axis
--! @details
--! This entity performs a rotation of a 3D vector (xi, yi, zi) around the Z-axis.
--!
--! The input vector is rotated in the XY plane by the specified angle (in fixed-point format), leaving the z component unchanged.
--!
--! Numerical Representation
--! - Coordinates (x, y, z):
--!   - Format: Two's complement signed number
--!   - Bit width: N + 2 bits (1 sign  + (N+1) magnitude)
--!   - Range: [-2^(N+1), 2^(N+1) - 1]
--!
--! - Angle:
--!   - Format: Q0.(N+1) fixed-point scaled radians.
--!   - Bit width: N + 2 bits (1 sign bit + (N+1) fractional bits)
--!   - Range: [-π, π) where π = 2^(N+1)
--!   - Resolution: π / 2^(N + 1) radians per LSB
--!   - Encoding: z_encoded = z_actual / (π / 2^(N + 1)), where z_actual is in
--!               radians.
--!
--! Interface behavior:
--! - Rotation begins when `start` is asserted for at least one rising edge of `clk`.
--! - After a latency of N + 2 cycles, the output vector (xo, yo, zo) becomes valid and `valid` is asserted high for one cycle.
entity z_axis_rotator is
  generic (
    --! @brief Number of CORDIC iterations
    --! @details Determines the rotation precision.    
    N: positive range 1 to 1023
  );
  
  port (
    --! @brief System clock
    clk: in std_logic;

    --! @brief Active-high asynchronous reset
    rst: in std_logic;

    --! @brief Start signal
    start: in std_logic;

    --! @brief X-coordinate input (signed integer)
    --! @details Range: [-2^(N+1), 2^(N+1) - 1]
    xi: in std_logic_vector(N + 1 downto 0);

    --! @brief Y-coordinate input (signed integer)
    --! @details Range: [-2^(N+1), 2^(N+1) - 1]
    yi: in std_logic_vector(N + 1 downto 0);

    --! @brief Z-coordinate input (signed integer)
    --! @details Range: [-2^(N+1), 2^(N+1) - 1]    
    zi: in std_logic_vector(N + 1 downto 0);

    --! @brief Z-axis rotation angle input (Q0.(N+1) fixed-point)
    --! @details Scaled radians: actual angle = zi × (π/2^(N+1))
    angle: in std_logic_vector(N + 1 downto 0);

    --! @brief X-coordinate output (signed integer)
    --! @details Rotated coordinate, same format as input    
    xo: out std_logic_vector(N + 1 downto 0);

    --! @brief Y-coordinate output (signed integer)
    --! @details Rotated coordinate, same format as input
    yo: out std_logic_vector(N + 1 downto 0);

    --! @brief Z-coordinate output (signed integer)
    --! @details Rotated coordinate, same format as input
    zo: out std_logic_vector(N + 1 downto 0);

    --! @brief Valid output data indicator
    valid: out std_logic
  );
end entity z_axis_rotator;

architecture structural of z_axis_rotator is

begin

  --! @brief XY-plane rotator (CORDIC core)
  xy_plane_rotator: entity work.cordic
    generic map (
      N => N
    )
    port map (
      clk   => clk,
      rst   => rst,
      start => start,
      xi    => xi,
      yi    => yi,
      zi    => angle,
      xo    => xo,
      yo    => yo,
      zo    => open,  -- NOTE: residual angle not needed
      valid => valid
    );

  --! Z-coordinate passthrough  
  zo <= zi;
  
end architecture structural;
