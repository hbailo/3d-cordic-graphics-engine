--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! @brief CORDIC processor for vector rotation
--! @details
--! This entity implements a CORDIC (COordinate Rotation DIgital Computer)
--! processor using a fixed-point representation in rotation mode. It performs vector
--! rotation (xi, yi) based on a given angle input (zi), computing the rotated coordinates (xo, yo)
--! and the residual angle (zo).
--!
--! The processor applies scaling correction for the gain accumulated by the CORDIC microrotations.
--!
--! Operation:
--! To initiate a rotation operation, assert the `start` signal high for at least
--! one rising edge of `clk`. The result will be available after a latency of `N + 2` clock cycles,
--! at which point the `valid` output flag will be asserted high..
--! 
--! Latency Characteristics
--! - Total latency: N + 2 clock cycles
--! - Throughput: 1 rotation per cycle (after first 'valid' output signal)
--! - Fully synchronous design with asynchronous reset
--! 
--! Numerical Representation
--! - Coordinates (x, y):
--!   - Format: Two's complement signed number
--!   - Bit width: N + 2 bits (1 sign  + (N+1) magnitude)
--!   - Range: [-2^(N+1), 2^(N+1) - 1]
--!
--! - Angles (z):
--!   - Format: Q0.(N+1) fixed-point scaled radians.
--!   - Bit width: N + 2 bits (1 sign bit + (N+1) fractional bits)
--!   - Range: [-π, π) where π = 2^(N+1)
--!   - Resolution: π / 2^(N + 1) radians per LSB
--!   - Encoding: z_encoded = z_actual / (π / 2^(N + 1)), where z_actual is in
--!               radians.
--! 
--! References:
--! [1] Behrooz, P. "Computer Arithmetic". (Oxford University Press, 2010)
entity cordic is
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
    
    --! @brief Rotation angle (Q0.(N+1) fixed-point)
    --! @details Scaled radians: actual angle = zi × (π/2^(N+1))
    zi: in std_logic_vector(N + 1 downto 0);

    --! @brief X-coordinate output (signed integer)
    --! @details Rotated coordinate, same format as input
    xo: out std_logic_vector(N + 1 downto 0);

    --! @brief Y-coordinate output (signed integer)
    --! @details Rotated coordinate, same format as input
    yo: out std_logic_vector(N + 1 downto 0);

    --! @brief Residual rotation angle (Q0.(N+1) fixed-point)
    --! @details Updated angle after rotation, same format as input
    zo: out std_logic_vector(N + 1 downto 0);

    --! @brief Output data valid indicator
    valid: out std_logic
  );
end cordic;

--! @brief Structural implementation of pipelined CORDIC processor
--! @details Instantiates and connects all pipeline stages:
--! 1. Preprocessor: Performs angle range reduction to [-π/2, π/2]
--! 2. N microrotation stages: Each rotates by arctan(2^-i)
--! 3. Postprocessor: Compensates CORDIC gain (1/K factor)
--!
--! ## Pipeline Characteristics
--! - Total stages: N + 2 (pre + N rotations + post)
--! - All stages are fully registered
architecture structural of cordic is                              

  --! @brief Array type for pipeline signal routing
  --! @details Used for X, Y, and Z pipeline registers between cordic stages.
  type slv_vector is array(natural range <>) of std_logic_vector;

  --! Internal pipeline signals for X, Y, and Z signals.
  signal xp: slv_vector(0 to N)(N + 1 downto 0);
  signal yp: slv_vector(0 to N)(N + 1 downto 0);
  signal zp: slv_vector(0 to N)(N + 1 downto 0);
  
begin

  --! @brief Input preprocessing stage
  --! @details Maps input angle from [-π, π] to [-π/2, π/2].
  cordic_preprocessor: entity work.cordic_preprocessor
    generic map (
      N => N
    )
    port map (
      clk => clk,
      rst => rst,
      xi  => xi,
      yi  => yi,
      zi  => zi,
      xo  => xp(0),
      yo  => yp(0),
      zo  => zp(0)      
    );

  --! @brief Microrotation stage pipeline
  --! @details Generates N iterative stages, each rotating by arctan(2^-i).
  cordic_pipeline: for i in 0 to N - 1 generate

    cordic_stage_i: entity work.cordic_stage
      generic map (
        N => N,
        I => i
      )
      port map (
        clk => clk,
        rst => rst,
        xi  => xp(i),
        yi  => yp(i),
        zi  => zp(i),
        xo  => xp(i + 1),
        yo  => yp(i + 1),
        zo  => zp(i + 1)
      );

  end generate cordic_pipeline;

  --! @brief Output postprocessing stage
  --! @details Compensates for CORDIC gain by multiplying by 1/K.
  cordic_postprocessor: entity work.cordic_postprocessor
    generic map (
      N => N
    )
    port map (
      clk => clk,
      rst => rst,
      xi  => xp(N),
      yi  => yp(N),
      zi  => zp(N),
      xo  => xo,
      yo  => yo,
      zo  => zo
    ); 

  --! @brief Pipeline synchronization controller
  --! @details Generates 'valid' pulse after full pipeline latency (N + 2 cycles).
  cordic_pipeline_synchronizer: entity work.cordic_pipeline_synchronizer
    generic map (
      PIPELINE_DEPTH => N + 2
    )
    port map (
      clk   => clk,
      rst   => rst,
      start => start,
      valid  => valid
    );
  
end structural;
