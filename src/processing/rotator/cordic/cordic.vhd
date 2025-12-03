--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! @brief CORDIC processor for vector rotation
--! @details
--! This entity implements a CORDIC (COordinate Rotation DIgital Computer)
--! processor using a fixed-point representation in rotation mode. It performs
--! cartesian vector rotation (xi, yi) based on a given angle input (zi),
--! computing the rotated coordinates (xo, yo) and the residual angle (zo).
--!
--! The processor applies scaling correction for the gain accumulated by the CORDIC microrotations.
--!
--! Operation
--! To initiate a rotation operation, assert the `start` signal high for at least
--! one rising edge of `clk`. The result will be available after a latency of `ITERS + 2` clock cycles,
--! at which point the `valid` output flag will be asserted high.
--! 
--! Timing Characteristics
--! - Fully synchronous design with asynchronous reset
--! - Total latency: ITERS + 2 clock cycles
--! - Throughput: 1 rotation per cycle (after first 'valid' output signal)
--! 
--! Numerical Representation
--! - Cartesian coordinates (x, y):
--!   - Format:    Two's complement signed number
--!   - Bit width: DATA_WIDTH bits: (1 sign bit + (DATA_WIDTH - 1) magnitude bits)
--!   - Range:     [-2^(DATA_WIDTH - 1), 2^(DATA_WIDTH - 1) - 1]
--!
--! - Angles (z):
--!   - Format:     Q0.(DATA_WIDTH - 1) fixed-point scaled radians.
--!   - Bit width:  DATA_WIDTH bits (1 sign bit + (DATA_WIDTH - 1) fractional bits)
--!   - Range:      [-π, π) where π = 2^(DATA_WIDTH - 1)
--!   - Resolution: π / 2^(DATA_WIDTH - 1) radians per LSB
--!   - Encoding:   z_actual = z_encoded * π / 2^(DATA_WIDTH - 1), where z_actual is in
--!                 radians
--! 
--! References
--! [1] Behrooz, P. "Computer Arithmetic". (Oxford University Press, 2010)
entity cordic is
    generic (
        --! Coordinates and angles bit width
        DATA_WIDTH: positive range 1 to 1023;
        
        --! Number of CORDIC iterations
        ITERS: positive range 1 to DATA_WIDTH - 2 := DATA_WIDTH - 2
    );
    
    port (
        --! System clock
        clk: in std_logic;

        --! Active-high asynchronous reset
        rst: in std_logic;

        --! Start signal
        start: in std_logic;
        
        --! X-coordinate input
        xi: in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Y-coordinate input
        yi: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        
        --! Rotation angle
        zi: in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! X-coordinate output
        xo: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Y-coordinate output
        yo: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Residual rotation angle
        zo: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Valid output flag
        valid: out std_logic
    );
end entity;

--! @brief Structural implementation of pipelined CORDIC processor
--! @details
--! Instantiates and connects all pipeline stages:
--! 1. Preprocessor: Performs angle range reduction to [-π/2, π/2]
--! 2. ITERS microrotation stages: Each rotates by arctan(2^-i)
--! 3. Postprocessor: Compensates CORDIC gain (1/K factor)
--!
--! Pipeline Characteristics
--! - Total stages: ITERS + 2 (pre + ITERS rotations + post)
--! - All stages are fully registered
architecture structural of cordic is                              
    --! @brief Array type for pipeline signal routing
    --! @details Used for X, Y, and Z pipeline registers between cordic stages.
    type slv_vector is array(natural range <>) of std_logic_vector;

    -- Internal pipeline signals for X, Y, and Z signals.
    signal xp: slv_vector(0 to ITERS)(DATA_WIDTH + 1 downto 0);
    signal yp: slv_vector(0 to ITERS)(DATA_WIDTH + 1 downto 0);
    signal zp: slv_vector(0 to ITERS)(DATA_WIDTH + 1 downto 0);
begin          
    --! @brief Input preprocessing stage
    --! @details Maps input angle from [-π, π] to [-π/2, π/2].
    cordic_preprocessor: entity work.cordic_preprocessor
        generic map (
            DATA_WIDTH => DATA_WIDTH
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
    cordic_pipeline: for i in 0 to ITERS - 1 generate
        cordic_stage_i: entity work.cordic_stage
            generic map (
                DATA_WIDTH => DATA_WIDTH + 2,
                ITERS      => ITERS,
                I          => i
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
    end generate;

    --! @brief Output postprocessing stage
    --! @details Compensates for CORDIC gain by multiplying by 1/K.
    cordic_postprocessor: entity work.cordic_postprocessor
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ITERS      => ITERS
        )
        port map (
            clk => clk,
            rst => rst,
            xi  => xp(ITERS),
            yi  => yp(ITERS),
            zi  => zp(ITERS),
            xo  => xo,
            yo  => yo,
            zo  => zo
        ); 

    --! @brief Pipeline synchronization controller
    --! @details Generates 'valid' pulse after full pipeline latency (ITERS + 2
    --! cycles) synchronized to start.
    cordic_pipeline_synchronizer: entity work.cordic_pipeline_synchronizer
        generic map (
            PIPELINE_DEPTH => ITERS + 2
        )
        port map (
            clk   => clk,
            rst   => rst,
            start => start,
            valid => valid
        );  
end architecture;
