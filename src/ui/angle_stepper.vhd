--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief Angle stepper controlled by up/down inputs.
--! @details
--! Implements a signed up/down counter that increments or decrements a discrete
--! angle value when @p up or @p down are asserted.  
--! If both signals are high, or both are low, the angle holds its value.  
entity angle_stepper is
    generic (
        --! Width of the angle register in bits
        ANGLE_WIDTH: positive
    );
    port (
        --! System clock
        clk: in std_logic;
        
        --! @brief Asynchronous reset.
        --! @details Active high. Clears the angle register.        
        rst: in std_logic;

        --! Increment command        
        up: in std_logic;

        --! Decrement command        
        down: in std_logic;
        
        --! @brief Current angle value
        angle: out std_logic_vector(ANGLE_WIDTH - 1 downto 0)
    );
end;

--! @brief Behavioral architecture of the angle stepper.
--! @details
--! Implements a signed register @p angle_reg updated on each rising edge of
--! @p clk.
--! Signed overflow / underflow wraps naturally.
architecture behavioral of angle_stepper is
    signal angle_reg: signed(angle'range);
begin
    process(clk, rst)
    begin
        if rst then
            angle_reg <= (others => '0');
        elsif rising_edge(clk) then
            if up and not down then
                angle_reg <= angle_reg + 1;
            elsif down and not up then
                angle_reg <= angle_reg - 1;
            end if;
        end if;
    end process;
    
    angle <= std_logic_vector(angle_reg);
end;
