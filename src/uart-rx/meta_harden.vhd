--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;

--! @brief Two-stage metastability hardener for asynchronous signals.
--!
--! @details
--! Synchronizes an asynchronous input (@p async) to the system clock (@p clk)
--! using two cascaded flip-flops, reducing metastability risk before use in
--! synchronous logic.
entity meta_harden is
    port (
        --! @brief System clock
        clk: in std_logic;

        --! @brief Async reset
        --! @details Active high
        rst: in std_logic;

        --! Asynchronous input signal
        async: in std_logic;

        --! Synchronized output signal
        sync: out std_logic
    );
end meta_harden;

--! @brief RTL implementation of a two-flop synchronizer.
architecture rtl of meta_harden is
    signal meta_ff: std_logic;
    signal sync_ff: std_logic;
begin

    process(clk, rst)
    begin
        if rst then
            meta_ff <= '1';
            sync_ff <= '1';
        elsif rising_edge(clk) then
            meta_ff <= async;
            sync_ff <= meta_ff;
        end if;
    end process;

    sync <= sync_ff;
end rtl;
