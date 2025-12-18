--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! @brief Synchronous simple dual-port RAM
--! @details
--! - One write port (A)
--! - One read-only port (B)
--! - Synchronous read with registered output
entity bram is
    generic (
        --! Address width in bits
        ADDR_WIDTH: integer;

        --! Data width in bits
        DATA_WIDTH: integer
    );
    port (
        --! System clock
        clk: in std_logic;

        --! Enable for port A
        en_a: in std_logic;

        --! Enable for port B
        en_b: in std_logic;
        
        --! Write enable for port A        
        we_a: in std_logic;

        --! Address for port A
        addr_a: in std_logic_vector(ADDR_WIDTH - 1 downto 0);

        --! Address for port B
        addr_b: in std_logic_vector(ADDR_WIDTH - 1 downto 0);

        --! Data input for port A
        din_a: in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Data output for port B
        dout_b: out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity;

--! @brief UG901 2023.2 Vivado manual implementation
--! @details Implements RAM storage and synchronous address registers
--! following UG901 2023.2 manual template for block ram inference.
architecture ug901 of bram is
    type ram_t is array (2**ADDR_WIDTH - 1 downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal ram: ram_t;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if en_a then
                if we_a then
                    ram(to_integer(unsigned(addr_a))) <= din_a;
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if en_b then
                dout_b <= ram(to_integer(unsigned(addr_b)));
            end if;
        end if;
    end process;
end architecture;
