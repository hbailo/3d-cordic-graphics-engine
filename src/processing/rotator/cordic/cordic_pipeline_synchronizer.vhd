--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;

--! @brief Pipeline synchronizer for fixed-latency CORDIC architecture
--! @details
--! This module generates a `valid` pulse after a fixed number of clock
--! rising edges (`PIPELINE_DEPTH`) following an initial `start` pulse.
entity cordic_pipeline_synchronizer is
  generic (
    --! Number of pipeline stages (latency cycles)
    PIPELINE_DEPTH: positive range 3 to 1025
  );

  port (
    --! System clock
    clk: in std_logic;
    
    --! Active-high asynchronous reset
    rst: in std_logic;

    --! Input start pulse indicating valid data entering the pipeline
    start: in std_logic;

    --! Output pulse aligned with the pipeline completion
    valid: out std_logic
  );
end entity;

--! @brief Behavioral architecture for pipeline synchronization
--! @details
--! A shift register of length `PIPELINE_DEPTH` propagates the `start`
--! pulse through the pipeline. After exactly `PIPELINE_DEPTH` cycles,
--! the MSB of the shift register drives the `valid` output.
architecture behavioral of cordic_pipeline_synchronizer is
    signal valid_shift_reg: std_logic_vector(PIPELINE_DEPTH - 1 downto 0);
begin
    process(clk, rst)
    begin
        if rst then
            valid_shift_reg <= (others => '0');
        elsif rising_edge(clk) then
            valid_shift_reg <= valid_shift_reg(PIPELINE_DEPTH - 2 downto 0) & start;
        end if;
    end process;

    valid <= valid_shift_reg(PIPELINE_DEPTH - 1);
end architecture;
