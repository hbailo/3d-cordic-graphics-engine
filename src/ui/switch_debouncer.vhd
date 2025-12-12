--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

--! @brief Debounces a mechanical switch
--! @details
--! Implements a synchronous debouncer for a single digital input switch.
--! The module filters out spurious transitions caused by mechanical bouncing
--! by waiting for a stable input over a defined debounce period.
entity switch_debouncer is
    generic (
        --! System clock frequency in Hz        
        CLK_FREQ_HZ: positive;

        --! Debounce period in milliseconds        
        DEBOUNCE_PERIOD_MS: positive
    );
    port (
        --! System clock        
        clk: in std_logic;

        --! Asynchronous active-high reset        
        rst: in std_logic;
        
        --! Raw switch input        
        sw: in std_logic;
        
        --! Debounced switch output        
        sw_db: out std_logic
    );
end entity;

--! @brief FSM architecture of the switch debouncer
--! @details
--! Operation:
--! - Captures input at each rising edge of clk
--! - Compares input with current debounced output
--! - If different, increments a timer
--! - If input remains stable for the debounce period, toggles debounced output
--! - Timer resets if input matches debounced output
architecture behavioral of switch_debouncer is
    constant TIMER_WIDTH: positive :=
        1 + integer(ceil(log2(real(CLK_FREQ_HZ * DEBOUNCE_PERIOD_MS / 1000 + 1))));

    signal sw_reg: std_logic;
    signal timer: unsigned(TIMER_WIDTH - 1 downto 0);
begin
    process (clk, rst)
    begin
        if rst then
            sw_reg <= '0';
            sw_db  <= '0';
            timer  <= (others => '0');
        elsif rising_edge(clk) then
            sw_reg <= sw;
            
            if sw_db = sw_reg then
                timer <= (others => '0');
            else
                timer <= timer + 1;

                if timer(TIMER_WIDTH - 1) then
                    sw_db <= not sw_db;
                end if;                
            end if;
        end if;
    end process;
end architecture;
