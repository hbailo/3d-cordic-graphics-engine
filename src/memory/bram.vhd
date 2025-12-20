--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! @brief Synchronous single-port block RAM
--! @details
--! Write first mode
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
        ena: in std_logic;
        
        --! Write enable
        we: in std_logic;

        --! Address
        addr: in std_logic_vector(ADDR_WIDTH - 1 downto 0);

        --! Data input
        din: in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Data output
        dout: out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity;

--! @brief UG901 2023.2 Vivado manual implementation
--! @details Implements synchronous RAM storage
--! following UG901 2023.2 manual template for block ram inference.
architecture ug901 of bram is
    type ram_t is array (2**ADDR_WIDTH - 1 downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal ram: ram_t;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if ena then
                if we then
                    ram(to_integer(unsigned(addr))) <= din;
                    dout <= din;
                else
                    dout <= ram(to_integer(unsigned(addr)));
                end if;
            end if;
        end if;
    end process;
end architecture;
