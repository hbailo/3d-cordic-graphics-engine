--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief Synchronous dual-port RAM
--! @details
--! - One write/read port (A)
--! - One read-only port (B)
--! - Synchronous read with registered addresses
entity dual_port_ram is
    generic (
        --! Address width in bits
        ADDR_WIDTH: integer;

        --! Data width in bits
        DATA_WIDTH: integer
    );
    port (
        --! System clock
        clk: in std_logic;

        --! Write enable for port A
        we: in std_logic;

        --! Address for port A
        addr_a: in std_logic_vector(ADDR_WIDTH - 1 downto 0);

        --! Address for port B
        addr_b: in std_logic_vector(ADDR_WIDTH - 1 downto 0);

        --! Data input for port A
        din_a: in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Data output for port A
        dout_a: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Data output for port B
        dout_b: out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end dual_port_ram;

--! @brief Xilinx implementation
--! @details Implements RAM storage and synchronous address registers
--! following xilinx's format for block ram inference.
architecture xilinx of dual_port_ram is
    type ram_t is array(0 to 2**ADDR_WIDTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal ram: ram_t;
    signal addr_a_reg: std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal addr_b_reg: std_logic_vector(ADDR_WIDTH - 1 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we then
                ram(to_integer(unsigned(addr_a))) <= din_a;
            end if;

            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
        end if;
    end process;

    dout_a <= ram(to_integer(unsigned(addr_a_reg)));
    dout_b <= ram(to_integer(unsigned(addr_b_reg)));
end xilinx;
