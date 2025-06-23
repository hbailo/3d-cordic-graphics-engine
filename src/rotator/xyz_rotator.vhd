--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief 3D vector rotator using sequential XYZ rotations
--!
--! @details
--! This entity performs 3D vector rotation over the full space using the
--! X-Y-Z rotation order.
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
entity xyz_rotator is
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

    --! @brief X-axis rotation angle (Q0.(N+1) fixed-point)
    --! @details Scaled radians: actual angle = zi × (π/2^(N+1))
    x_angle: in std_logic_vector(N + 1 downto 0);

    --! @brief Y-axis rotation angle (Q0.(N+1) fixed-point)
    --! @details Scaled radians: actual angle = zi × (π/2^(N+1))    
    y_angle: in std_logic_vector(N + 1 downto 0);

    --! @brief Z-axis rotation angle (Q0.(N+1) fixed-point)
    --! @details Scaled radians: actual angle = zi × (π/2^(N+1))    
    z_angle: in std_logic_vector(N + 1 downto 0);

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
end entity xyz_rotator;

--! @brief Structural implementation of 3D coordinate rotator
--! @details This architecture implements a 3D rotation by cascading three CORDIC-based
--! single-axis rotators (X, Y, Z). The rotation is performed in XYZ order.
architecture structural of xyz_rotator is

  --! @brief Intermediate vector signals between rotators
  signal x1, y1, z1: std_logic_vector(N + 1 downto 0); --!< Vector after x-axis rotation
  signal x2, y2, z2: std_logic_vector(N + 1 downto 0); --!< Vector after y-axis rotation

  --! @brief Internal valid signals between rotators
  signal valid_x_rotation: std_logic;  --!< Valid signal after x-axis rotation
  signal valid_y_rotation: std_logic;  --!< Valid signal after y-axis rotation

begin

  --! @brief X-axis rotator
  x_axis_rotator: entity work.x_axis_rotator
    generic map (
      N => N
    )
    port map (
      clk   => clk,
      rst   => rst,
      start => start,
      xi    => xi,
      yi    => yi,
      zi    => zi,
      angle => x_angle,
      xo    => x1,
      yo    => y1,
      zo    => z1,
      valid => valid_x_rotation
    );

  --! @brief Y-axis rotator
  y_axis_rotator: entity work.y_axis_rotator
    generic map (
      N => N
    )
    port map (
      clk   => clk,
      rst   => rst,
      start => valid_x_rotation,
      xi    => x1,
      yi    => y1,
      zi    => z1,
      angle => y_angle,
      xo    => x2,
      yo    => y2,
      zo    => z2,
      valid => valid_y_rotation
    );

  --! @brief Z-axis rotator
  z_axis_rotator: entity work.z_axis_rotator
    generic map (
      N => N
    )
    port map (
      clk   => clk,
      rst   => rst,
      start => valid_y_rotation,
      xi    => x2,
      yi    => y2,
      zi    => z2,
      angle => z_angle,
      xo    => xo,
      yo    => yo,
      zo    => zo,
      valid => valid
    );  

end architecture structural;
