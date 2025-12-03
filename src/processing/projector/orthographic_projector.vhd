--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;

--! @brief Orthographic projector for 3D coordinates.
--! @details
--! Projects 3D coordinates (xi, yi, zi) onto the 2D cartesian plane (y, z),
--! discarding the x-axis component. The projection is synchronous to the clock.
--! On reset, the outputs are cleared to zero.
entity orthographic_projector is
    generic (
        --! Coordinates bit width
        DATA_WIDTH : positive range 1 to 1023
    );

    port (
        --! System clock
        clk : in std_logic;

        --! Active-high asynchronous reset
        rst : in std_logic;

        --! Start signal
        start : in std_logic;

        --! X coordinate input
        xi : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Y coordinate input
        yi : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Z coordinate input
        zi : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! x projected coordinate
        x : out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! y projected coordinate
        y : out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Valid output flag
        valid : out std_logic
    );
end entity;

--! @brief Behavioral architecture of orthographic_projector.
--! @details
--! The architecture consists of signal registers.
architecture behavioral of orthographic_projector is
begin
    process(clk, rst)
    begin
        if rst then
            x     <= (others => '0');
            y     <= (others => '0');
            valid <= '0';
        elsif rising_edge(clk) then
            x     <= yi;
            y     <= zi;
            valid <= start;
        end if;
    end process;
end architecture;        
