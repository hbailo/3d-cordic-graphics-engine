--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

--! @brief CORDIC post-processor for gain compensation
--! @details
--! This module compensates for the CORDIC gain factor by multiplying the
--! output coordinates by the reciprocal of the accumulated scaling factor (K):
--!
--!     K = ∏(√(1 + 2⁻²ⁱ)) for i = 0 to N - 1
--!
--! Number formats:
--! - Coordinates (x, y): Signed integers in two's complement format
--!   - Format: 1 sign bit + (N+1) magnitude bits
--!   - Numerical range: [-2^(N+1), 2^(N+1) - 1]
entity cordic_postprocessor is
  generic (
    --! @brief Total number of CORDIC iterations in the pipeline    
    N: positive range 1 to 1023    
  );
  
  port (
    --! @brief X-coordinate input (signed integer)
    --! @details Range: [-2^(N+1), 2^(N+1) - 1]    
    xi: in std_logic_vector(N + 1 downto 0);

    --! @brief Y-coordinate input (signed integer)
    --! @details Range: [-2^(N+1), 2^(N+1) - 1]    
    yi: in std_logic_vector(N + 1 downto 0);

    --! @brief Gain-compensated X-coordinate output (signed integer)
    xo: out std_logic_vector(N + 1 downto 0);

    --! @brief Gain-compensated Y-coordinate output (signed integer)    
    yo: out std_logic_vector(N + 1 downto 0)
  );
end entity cordic_postprocessor;

--! @brief Dataflow architecture for CORDIC gain compensation
--! @details
--! The architecture performs the following operations:
--! 1. Calculates the reciprocal CORDIC gain factor for N iterations
--! 2. Multiplies input coordinates by the reciprocal gain (1/K)
--! 3. Truncates the result to maintain the output size
architecture dataflow of cordic_postprocessor is

  --! @brief Calculate the reciprocal CORDIC gain factor
  --! @details
  --! Calculates the precise reciprocal of the CORDIC scaling factor K, where:
  --! 
  --!     K = ∏(√(1 + 2⁻²ⁱ)) for i = 0 to n_iter-1
  --!
  --! @param n_iter Number of CORDIC iterations (determines precision)
  --! @return Reciprocal gain factor (1/K) as real value
  function cordic_reciprocal_gain(n_iter: positive) return real is
    
    variable k: real := 1.0;
    
  begin
    
    for i in 0 to n_iter - 1 loop
      k := k * sqrt(1.0 + 2.0**(-2 * i));
    end loop;
    
    return 1.0 / k;
    
  end function;

  --! @brief Reciprocal CORDIC gain constant for N iterations
  --! @details Stored as fixed-point value with scaling factor 2^(N+1).
  constant K_INV: signed(N + 1 downto 0) :=
    to_signed(
      integer(
        round(
          2.0**(N + 1) *             -- Scaling factor
          cordic_reciprocal_gain(N)  -- CORDIC reciprocal gain
        )
      ),
      N + 2
    );
  
  -- Internal signed versions of inputs
  signal xi_s: signed(xi'range);  --! Signed version of xi input
  signal yi_s: signed(yi'range);  --! Signed version of yi input

  -- Internal signed versions of outputs
  signal xo_s: signed(xo'range);  --! Signed version of xo output 
  signal yo_s: signed(yo'range);  --! Signed version of yo output
                                  
begin

  -- Input type conversion
  xi_s <= signed(xi);
  yi_s <= signed(yi);
  
  -- Gain correction
  xo_s <= resize(shift_right(xi_s * K_INV, N + 1), xo'length);
  yo_s <= resize(shift_right(yi_s * K_INV, N + 1), yo'length);

  -- Output type conversion
  xo <= std_logic_vector(xo_s);
  yo <= std_logic_vector(yo_s);

end architecture dataflow;
