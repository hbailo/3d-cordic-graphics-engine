--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! @brief Pipeline synchronizer for fixed-latency CORDIC architecture
--! @details
--! This module generates a `valid` pulse after a fixed number of clock
--! rising edges (`PIPELINE_DEPTH`) following an initial `start` pulse.
--!
--! Notes:
--! - The synchronizer ignores new `start` pulses while it is already running.
--! - The latency `PIPELINE_DEPTH` must be ≥ 2.
entity cordic_pipeline_synchronizer is
  generic (
    --! @brief Number of pipeline stages (latency cycles)
    PIPELINE_DEPTH: positive range 2 to 1025
  );

  port (
    --! @brief System clock    
    clk: in std_logic;
    
    --! @brief Active-high asynchronous reset
    rst: in std_logic;

    --! @brief Start pulse to initiate pipeline synchronization
    --! @details This must be asserted for one clock cycle to begin the internal counter.
    start: in std_logic;

    --! @brief Valid output pulse    
    valid: out std_logic
  );
end entity cordic_pipeline_synchronizer;

--! @brief Behavioral architecture for pipeline synchronization
--! @details
--! Implements a counter-based synchronizer that asserts `valid` after a fixed latency.
--! Internally tracks the elapsed cycles using an unsigned counter, and resets
--! all state asynchronously on `rst`.
architecture behavioral of cordic_pipeline_synchronizer is

  --! @brief Bit width of internal counter based on PIPELINE_DEPTH  
  constant PIPELINE_DEPTH_BIT_LENGTH: natural := integer(ceil(log2(real(PIPELINE_DEPTH + 1))));

  --! @brief Internal cycle counter  
  signal counter: unsigned(PIPELINE_DEPTH_BIT_LENGTH - 1 downto 0);

  --! @brief Synchronizer running flag
  signal running: std_logic;
    
begin
  
  process(clk, rst)
  begin
    
    if rst then
      -- Asynchronous reset      
      running <= '0';      
      counter <= (others => '0');
      valid   <= '0';
      
    elsif rising_edge(clk) then
      
      if running then
        
        if counter = PIPELINE_DEPTH - 1 then
          valid <= '1';
        else
          counter <= counter + 1 ;
        end if;
        
      elsif start then
        running <= '1';
        counter <= to_unsigned(1, counter'length);
      end if;
      
    end if;
    
  end process;
  
end architecture behavioral;
