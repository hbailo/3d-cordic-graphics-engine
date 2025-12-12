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
--! References:
--! [1] Behrooz, P. "Computer Arithmetic". (Oxford University Press, 2010)
entity cordic_stage is
    generic (
        --! Coordinates and angles bit width
        DATA_WIDTH: positive;
        
        --! Number of CORDIC iterations
        ITERS: positive := DATA_WIDTH - 2;      
        
        --! Current iteration step
        I: natural range 0 to ITERS - 1
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
        
        --! Residual angle input
        zi: in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! X-coordinate output 
        xo: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Y-coordinate output 
        yo: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Residual angle output
        zo: out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity;

--! @brief Behavioral architecture of the CORDIC stage
--! @details
--! Implements the CORDIC rotation iteration using arithmetic shifts
--! and additions.
--!
--! The architecture consists of:
--! 1. Angle calculation (precomputed constant)
--! 2. Rotation direction decision logic
--! 3. Coordinate rotation logic
--! 4. Registered outputs
architecture behavioral of cordic_stage is
    --! @brief Precomputed elementary angle for this iteration
    --! @details Stored in Q0.(DATA_WIDTH - 1) fixed-point format.
    --! Computed as: EI = round(2^(DATA_WIDTH - 1) / π * arctan(2^-I))  
    constant EI: signed(zi'range) :=
        to_signed(
            integer(
                round(
                    2.0**(ITERS + 1) / MATH_PI *  -- Scaling factor
                    arctan(2.0**(-I))             -- arctan(2^-I)
                    )
                ),
            zi'length
            );

    -- Internal signed versions of inputs
    signal xi_s: signed(xi'range);  --! Signed version of xi input
    signal yi_s: signed(yi'range);  --! Signed version of yi input
    signal zi_s: signed(zi'range);  --! Signed version of zi input

    -- Internal signed versions of outputs
    signal xo_s: signed(xo'range);  --! Signed version of xo output before registration
    signal yo_s: signed(yo'range);  --! Signed version of yo output before registration
    signal zo_s: signed(zo'range);  --! Signed version of zo output before registration
    
    --! @brief Rotation sense indicator
    --! @details
    --! di = '0' => counterclockwise rotation  
    --! di = '1' => clockwise rotation
    --! Derived from the sign bit of the residual angle zi.  
    signal di: std_logic;

    -- Shifted coordinate signals
    signal xi_sra_i: signed(xi'range);  --! xi shifted right arithmetically by I
    signal yi_sra_i: signed(yi'range);  --! yi shifted right arithmetically by I
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
            zo <= std_logic_vector(zo_s);
        end if;
    end process;
end architecture;
