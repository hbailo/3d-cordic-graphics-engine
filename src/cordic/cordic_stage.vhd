--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_1164.all;

--! @brief Single iteration stage of CORDIC algorithm in rotation mode
--! @details
--! This entity implements one iteration step of the CORDIC (COordinate Rotation
--! DIgital Computer) algorithm in rotation mode. Outputs are registered for
--! direct pipeline implementation.
--!
--! This stage performs [1]:
--! - x(i+1) = x(i) - d(i) y(i) 2^(-i)
--! - y(i+1) = y(i) + d(i) x(i) 2^(-i)
--! - z(i+1) = z(i) - d(i) arctan(2^(-i))
--! 
--! where d(i) determines the rotation sense.
--! 
--! Number formats:
--! - Coordinates (x, y): Signed integers in two's complement format
--!   - Format: 1 sign bit + (N+1) magnitude bits
--!   - Numerical range: [-2^(N+1), 2^(N+1) - 1]
--!
--! - Angles (z): Fixed-point radians in Q0.(N+1) format
--!   - Format: 1 sign bit + 0 integer bits + (N+1) fractional bits
--!   - Numerical range: [-π, π) where π = 2^(N+1)
--!   - Resolution: π / 2^(N+1) radians per LSB
--!   - Encoding: z_actual = z_encoded * (π / 2^(N + 1))
--! 
--! References:
--!
--! [1] Behrooz, P. "Computer Arithmetic". (Oxford University Press, 2010)

entity cordic_stage is
  generic (
    --! @brief Total number of CORDIC iterations in the pipeline
    N : natural range 1 to 1023;
    
    --! @brief Current iteration index
    I : natural range 0 to N - 1
  );
  
  port (
    --! @brief System clock
    clk : in  std_logic;

    --! @brief Active-high asynchronous reset
    rst : in  std_logic;
    
    --! @brief X-coordinate input (signed integer)
    --! @details Range: [-2^(N+1), 2^(N+1) - 1]
    xi : in  std_logic_vector(N + 1 downto 0);

    --! @brief Y-coordinate input (signed integer)
    --! @details Range: [-2^(N+1), 2^(N+1) - 1]
    yi : in  std_logic_vector(N + 1 downto 0);
    
    --! @brief Residual angle input (Q0.(N+1) fixed-point)
    --! @details Scaled radians: actual angle = zi × (π/2^(N+1))
    zi : in  std_logic_vector(N + 1 downto 0);

    --! @brief X-coordinate output (signed integer)
    --! @details Rotated coordinate, same format as input
    xo : out std_logic_vector(N + 1 downto 0);

    --! @brief Y-coordinate output (signed integer)
    --! @details Rotated coordinate, same format as input
    yo : out std_logic_vector(N + 1 downto 0);

    --! @brief Residual angle output (Q0.(N+1) fixed-point)
    --! @details Updated angle after rotation, same format as input
    zo : out std_logic_vector(N + 1 downto 0)
  );
end cordic_stage;

--! @brief Dataflow architecture of the CORDIC stage
--! @details
--! Implements the CORDIC rotation iteration using arithmetic shifts
--! and additions.
--!
--! The architecture consists of:
--! 1. Angle calculation (precomputed constant)
--! 2. Rotation direction decision logic
--! 3. Coordinate rotation logic
--! 4. Registered outputs
architecture dataflow of cordic_stage is

  --! @brief Precomputed elementary angle for this iteration
  --! @details Stored in Q0.(N+1) fixed-point format.
  --! Computed as: EI = round(2^(N+1) / π * arctan(2^-I))  
  constant EI : signed(zi'range) :=
    to_signed(
      integer(
        round(
          2.0**(N + 1) / MATH_PI *  -- Scaling factor
          arctan(2.0**(-I))         -- arctan(2^-I)
        )
      ),
      zi'length
    );

  -- Internal signed versions of inputs
  signal xi_s : signed(xi'range);  --! Signed version of xi input
  signal yi_s : signed(yi'range);  --! Signed version of yi input
  signal zi_s : signed(zi'range);  --! Signed version of zi input

  -- Internal signed versions of outputs
  signal xo_s : signed(xo'range);  --! Signed x output before registration
  signal yo_s : signed(yo'range);  --! Signed y output before registration
  signal zo_s : signed(zo'range);  --! Signed z output before registration
  
  --! @brief Rotation sense indicator
  --! @details
  --! di = '0' => counterclockwise rotation  
  --! di = '1' => clockwise rotation
  --! Derived from the sign bit of the residual angle zi.  
  signal di : std_logic;

  -- Shifted coordinate signals
  signal xi_sra_i : signed(xi'range);  --! xi shifted right arithmetically by I
  signal yi_sra_i : signed(yi'range);  --! yi shifted right arithmetically by I
  
begin

  -- Input type conversion
  xi_s <= signed(xi);
  yi_s <= signed(yi);
  zi_s <= signed(zi);
  
  -- Rotation sense determination (sign bit indicates direction)
  di <= zi(zi'left);

  -- Coordinate shifting
  xi_sra_i <= xi_s sra I;
  yi_sra_i <= yi_s sra I;

  -- CORDIC rotation equations
  -- X-coordinate rotation: implements x(i+1) = x(i) - d(i)*y(i)*2^-i
  xo_s <= xi_s - yi_sra_i when di = '0' else  -- Counterclockwise
          xi_s + yi_sra_i;                    -- Clockwise

  -- Y-coordinate rotation: implements y(i+1) = y(i) + d(i)*x(i)*2^-i  
  yo_s <= yi_s + xi_sra_i when di = '0' else  -- Counterclockwise
          yi_s - xi_sra_i;                    -- Clockwise

  -- Angle accumulator update: implements z(i+1) = z(i) - d(i)*arctan(2^-i)
  zo_s <= zi_s - EI when di = '0' else        -- Counterclockwise
          zi_s + EI;                          -- Clockwise

  -- Output registration
  process(clk, rst)
  begin
    
    if rst then
      -- Asynchronous reset
      xo <= (others => '0');
      yo <= (others => '0');
      zo <= (others => '0');
      
    elsif rising_edge(clk) then
      -- Registered outputs
      xo <= std_logic_vector(xo_s);
      yo <= std_logic_vector(yo_s);
      zo <= std_logic_vector(zo_s);
      
    end if;
    
  end process;

end dataflow;
