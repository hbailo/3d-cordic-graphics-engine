--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;

--! @brief Generates a 1-clock-cycle pulse on the rising edge of an input signal.
--! @details
--! Detects a rising transition on input @p din and outputs a single-cycle pulse on
--! @p pulse. Fully synchronous with @p clk. Reset clears internal state.
entity rising_edge_detector is
    port (
        --! System clock
        clk: in  std_logic;

        --! @brief Asynchronous reset
        --! @details Active high        
        rst: in  std_logic;
        
        --! Input signal to detect rising edge        
        din: in  std_logic;
        
        --! @brief Single-cycle pulse generated on rising edge of @p din        
        pulse: out std_logic
    );
end entity;

--! @brief Behavioral architecture.
--! @details
--! Compares the current input with the registered value to detect a rising edge.
architecture behavioral of rising_edge_detector is
    signal din_prev: std_logic;
begin
    process(clk, rst)
    begin
        if rst then
            din_prev <= '0';
        elsif rising_edge(clk) then
            din_prev <= din;
        end if;
    end process;

    pulse <= din and not din_prev;
end architecture;
