--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all ;

--! @brief Baud rate x16 clock enable generator for UART communication
--! @details
--! Generates a one-cycle pulse (@p baud_x16_ena) at 16× the configured
--! baud rate, derived from the system clock via an integer divider:
--! @code
--!     CLK_DIVIDER = round(CLK_FREQ / (16 × BAUD_RATE))
--! @endcode
--! Used to drive UART receiver sampling logic.
--! @note
--!     @p CLK_FREQ and @p BAUD_RATE are constrained such that @p CLK_FREQ is 
--!     at least twice as large as 16 times @p BAUD_RATE.
--! @note
--!     The output @p baud_x16_ena is a one-clock-cycle-wide pulse.
entity baud_rate_generator is
    generic (
        --! @brief System clock frequency in Hz
        CLK_FREQ: positive;
        
        --! @brief UART baud rate in bits per second
        BAUD_RATE: positive range 1 to CLK_FREQ / 32
    );
    
    port (
        --! @brief System clock
        clk: in std_logic;
        
        --! @brief Async reset
        --! @details Active high
        rst: in std_logic;

        --! @brief Sync enable input
        --! @details When deasserted, the internal counter is held reset and no pulses are generated.
        ena: in std_logic;
        
        --! @brief Clock enable output pulse
        --! @details 1-cycle enable pulse at approximately 16 x baud rate
        baud_x16_ena: out std_logic
    );
end baud_rate_generator;

--! @brief Behavioral architecture of the baud rate generator
--! @details
--! Implements a clock divider that generates periodic enable pulses
--! at 16 times the specified baud rate.
--!
--! The implementation consists of:
--! 1. A free-running counter that increments on each rising clock edge while
--! @p ena = '1'.
--! 2. Terminal count detection logic that:
--!    - Resets the counter when reaching CLK_DIVIDER - 1
--!    - Generates a single-cycle enable pulse
--! 3. If @p ena = '0' or @p rst = '1', the counter resets and the output pulse is suppressed.
architecture behavioral of baud_rate_generator is  
    --! @brief Clock divider to generate approximately 16 x baud rate pulses
    constant CLK_DIVIDER: positive := (CLK_FREQ + 8 * BAUD_RATE) / (16 * BAUD_RATE);

    --! @brief Bit width required for the clk tick counter 
    constant TICK_COUNTER_WIDTH: positive :=
        integer(
            ceil(
                log2(
                    real(CLK_DIVIDER + 1)
                )
            )
        );

    --! @brief Clk tick counter
    signal tick_counter: unsigned(TICK_COUNTER_WIDTH - 1 downto 0);
begin
    process(clk, rst)
    begin
        if rst then
            tick_counter <= (others => '0');      
        elsif rising_edge(clk) then
            if not ena then
                tick_counter <= (others => '0');
            elsif tick_counter = CLK_DIVIDER - 1 then
                tick_counter <= (others => '0');
            else
                tick_counter <= tick_counter + 1;
            end if;
        end if;
    end process;

    baud_x16_ena <= '1' when tick_counter = CLK_DIVIDER - 1 else
                    '0';
end behavioral;
