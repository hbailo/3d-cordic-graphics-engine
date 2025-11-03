--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;

--! @brief Orthographic projector for 3D coordinates.
--! @details
--! Projects 3D coordinates (xi, yi, zi) onto a 2D orthographic plane (xo, yo),
--! discarding the z-axis component. The projection is synchronous to the clock.
--! On reset, the outputs are cleared to zero.
entity orthographic_projector is
    generic (
        --! Size of coordinates
        N: positive range 1 to 1023
    );
  
    port (
        --! @brief System clock
        clk: in std_logic;

        --! @brief Asynchronous reset
        --! @details Active high
        rst: in std_logic;


        --! @brief X-axis input coordinate        
        xi: in std_logic_vector(N-1 downto 0);
        
        --! @brief Y-axis input coordinate        
        yi: in std_logic_vector(N-1 downto 0);

        --! @brief Z-axis input coordinate        
        zi: in std_logic_vector(N-1 downto 0);

        --! @brief X-axis projected output coordinate                
        xo: out std_logic_vector(N-1 downto 0);

        --! @brief Y-axis projected output coordinate                        
        yo: out std_logic_vector(N-1 downto 0)
    );
end orthographic_projector;

--! @brief Behavioral architecture of orthographic_projector.
--! @details
--! The architecture consists of a single synchronous process.
architecture behavioral of orthographic_projector is
begin
    process(clk, rst)
    begin
        if rst then
            xo <= (others => '0');
            yo <= (others => '0');
        elsif rising_edge(clk) then
            xo <= xi;
            yo <= yi;
        end if;
    end process;
end behavioral;        
