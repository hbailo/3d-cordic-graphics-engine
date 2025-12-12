--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! @brief CORDIC angle preprocessor for full [-π, π] range
--! @details 
--! This module performs angle range reduction for CORDIC algorithm, mapping
--! input angles from [-π, π] range to [-π/2, π/2] range while preserving
--! the original rotation through coordinate quadrant adjustments.
--! It extends the output coordinates and angles to avoid overflow.
entity cordic_preprocessor is
    generic (
        --! Coordinates and angles bit width
        DATA_WIDTH: positive
    );
    
    port (
        --! System clock    
        clk: in std_logic;

        --! Active-high asynchronous reset
        rst: in std_logic;
        
        --! Initial x-coordinate before rotation (signed integer
        xi: in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Initial y-coordinate before rotation
        yi: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        
        --! Initial rotation angle
        zi: in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Adjusted extended x-coordinate after quadrant adjustment
        xo: out std_logic_vector(DATA_WIDTH + 1 downto 0);

        --! Adjusted extended y-coordinate after quadrant adjustment
        yo: out std_logic_vector(DATA_WIDTH + 1 downto 0);

        --! Reduced extended rotation angle after quadrant adjustment
        zo: out std_logic_vector(DATA_WIDTH + 1 downto 0)
    );
end entity;

--! @brief Behavioral architecture of the angle range reduction
--! @details
--! The architecture performs the following transformation rules:
--! 1. For zi < -π/2:
--!    - Angle: z_out = z_in + π
--!    - Coordinates: (x_out, y_out) = (-x_in, -y_in)
--! 2. For zi > π/2:
--!    - Angle: z_out = z_in - π
--!    - Coordinates: (x_out, y_out) = (-x_in, -y_in)
--! 3. Otherwise (zi in [-π/2, π/2])
--!    - Pass-through unchanged
architecture behavioral of cordic_preprocessor is
    --! π/2 constant in Q0.(DATA_WIDTH - 1) format
    constant PI_OVER_2: signed(zo'range) := to_signed(2**(zi'length - 2), zo'length);

    --! -π constant in Q0.(DATA_WIDTH - 1) format 
    constant NEG_PI: signed(zo'range) := to_signed(-2**(zi'length - 1), zo'length); 

    -- Internal signed versions of inputs
    signal xi_s: signed(xo'range);  --! Signed extended version of xi input
    signal yi_s: signed(yo'range);  --! Signed extended version of yi input
    signal zi_s: signed(zo'range);  --! Signed extended version of zi input

    -- Internal signed versions of outputs
    signal xo_s: signed(xo'range);  --! Signed version of xo output 
    signal yo_s: signed(yo'range);  --! Signed version of yo output 
    signal zo_s: signed(zo'range);  --! Signed version of zo output
    
begin
    -- Input type conversion and extension
    xi_s <= resize(signed(xi), xi_s'length);
    yi_s <= resize(signed(yi), yi_s'length);
    zi_s <= resize(signed(zi), zi_s'length);

    -- Coordinate adjustment
    xo_s <= -xi_s when (zi_s < -PI_OVER_2 or zi_s > PI_OVER_2) else
            xi_s;

    yo_s <= -yi_s when (zi_s < -PI_OVER_2 or zi_s > PI_OVER_2) else
            yi_s;

    -- Angle range reduction  
    zo_s <= zi_s - NEG_PI when zi_s < -PI_OVER_2 else
            zi_s + NEG_PI when zi_s >  PI_OVER_2 else
            zi_s;

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
