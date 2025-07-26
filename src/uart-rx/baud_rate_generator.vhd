--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all ;

--! @brief Baud rate clock enable generator for UART communication
--! @details
--! This entity generates a baud rate enable pulse (@p baud_x16_ena)
--! for a UART receiver. The output signal pulses at 16 times the 
--! configured baud rate (16x oversampling) and is used to enable
--! sampling logic in downstream UART components.
--!
--! The frequency of the pulses is derived from the system clock
--! (@p clk) by using a counter-based clock divider.
--!
--! The divisor is calculated using the formula:
--!     CLK_DIVIDER = round(CLK_FREQ / (16 × BAUD_RATE))
--!
--! @note
--!     Assumes @p CLK_FREQ is significantly higher than 16 x @p BAUD_RATE.
--!     The output @p baud_x16_ena is a one-clock-cycle-wide pulse.
entity baud_rate_generator is
  generic (
    --! @brief System clock frequency in Hz
    CLK_FREQ: positive;
    
    --! @brief UART baud rate in bits per second
    BAUD_RATE: positive
  );
  
  port (
    --! @brief System clock
    clk: in std_logic;
    
    --! @brief Asynchronous active-high reset
    rst: in std_logic;
    
    --! @brief Clock enable output pulse
    --! @details 1-cycle enable pulse at approximately 16 x baud rate
    baud_x16_ena: out std_logic
  );
end baud_rate_generator;

--! @brief Behavioral architecture of the baud rate generator
--! @details
--! This architecture implements a clock divider that generates periodic enable pulses
--! at 16 times the specified baud rate.
--!
--! The implementation consists of:
--! 1. A free-running counter that increments on each rising clock edge
--! 2. Terminal count detection logic that:
--!    - Resets the counter when reaching CLK_DIVIDER - 1
--!    - Generates a single-cycle enable pulse
architecture behavioral of baud_rate_generator is
  
  --! @brief Clock divider to generate approximately 16 x baud rate pulses
  constant CLK_DIVIDER: positive := (CLK_FREQ + 8 * BAUD_RATE) / (16 * BAUD_RATE);

  --! @brief Bit width required for the tick counter 
  constant TICK_COUNTER_WIDTH: positive :=
    integer(
      ceil(
        log2(
          real(CLK_DIVIDER + 1)
        )
      )
    );

  --! @brief Internal tick counter register 
  signal tick_counter: unsigned(TICK_COUNTER_WIDTH - 1 downto 0);
  
begin

  -- Clock divider process
  process(clk, rst)
  begin

    if rst then
      -- Asynchronous reset
      tick_counter <= (others => '0');
      baud_x16_ena <= '0';
      
    elsif rising_edge(clk) then
      -- Counter logic
      
      if tick_counter = CLK_DIVIDER - 1 then
        tick_counter <= (others => '0');
        baud_x16_ena <= '1';
        
      else
        tick_counter <= tick_counter + 1;
        baud_x16_ena <= '0';
      end if;
      
    end if;
    
  end process;
  
end behavioral;
