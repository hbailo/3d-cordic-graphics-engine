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
--!     K = ∏(√(1 + 2⁻²ⁱ)) for i = 0 to ITERS - 1
--!
--! Outputs are registered for direct pipeline implementation.
--! 
--! References
--! [1] Behrooz, P. "Computer Arithmetic". (Oxford University Press, 2010)
entity cordic_postprocessor is
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
        
        --! X-coordinate input
        xi: in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Y-coordinate input
        yi: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        
        --! Residual rotation angle
        zi: in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! @brief Gain-compensated X-coordinate output
        xo: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! @brief Gain-compensated Y-coordinate output
        yo: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! @brief Registered residual angle
        zo: out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity;

--! @brief Behavioral architecture for CORDIC gain compensation
--! @details
--! The architecture performs the following operations:
--! 1. Calculates the reciprocal CORDIC gain factor for ITERS iterations
--! 2. Multiplies input coordinates by the reciprocal gain (1/K)
--! 3. Truncates the result to maintain the output size
--! 4. Registers outputs
architecture behavioral of cordic_postprocessor is
    --! @brief Calculate the reciprocal CORDIC gain factor
    --! @details
    --! Calculates the precise reciprocal of the CORDIC scaling factor K, where:
    --! 
    --!     K = ∏(√(1 + 2⁻²ⁱ)) for i = 0 to n_iter-1
    --!
    --! @param iters Number of CORDIC iterations (determines precision)
    --! @return Reciprocal gain factor (1/K) as real value
    function cordic_reciprocal_gain(iters: positive) return real is
        variable k: real := 1.0;
    begin
        for i in 0 to iters - 1 loop
            k := k * sqrt(1.0 + 2.0**(-2 * i));
        end loop;
        
        return 1.0 / k;
    end function;

    --! @brief Reciprocal CORDIC gain constant for ITERS iterations
    --! @details Stored as fixed-point value with scaling factor 2^(DATA_WIDTH - 1)
    constant K_INV: signed(DATA_WIDTH - 1 downto 0) :=
        to_signed(
            integer(
                round(
                    2.0**(DATA_WIDTH - 1) *        -- Scaling factor
                    cordic_reciprocal_gain(ITERS)  -- CORDIC reciprocal gain
                    )
                ),
            DATA_WIDTH
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
    xo_s <= resize(shift_right(xi_s * K_INV, DATA_WIDTH - 1), DATA_WIDTH);
    yo_s <= resize(shift_right(yi_s * K_INV, DATA_WIDTH - 1), DATA_WIDTH);

    -- Output registers
    process(clk, rst)
    begin
        if rst then
            xo <= (others => '0');
            yo <= (others => '0');
            zo <= (others => '0');
        elsif rising_edge(clk) then
            xo <= std_logic_vector(xo_s);
            yo <= std_logic_vector(yo_s);
            zo <= zi;
        end if;
    end process;
end architecture;
