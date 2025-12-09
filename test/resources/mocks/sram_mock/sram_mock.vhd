library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity sram_mock is
    generic (
        ADDR_WIDTH: positive range 1 to 18
    );
    port (
        addr: in std_logic_vector(17 downto 0);
        dio: inout std_logic_vector(15 downto 0);
        ce_n: in std_logic;        
        we_n: in std_logic;
        oe_n: in std_logic;
        ub_n: in std_logic;
        lb_n: in std_logic
    );
end entity;

architecture behavioral of sram_mock is
    type sram_t is array(0 to 2**ADDR_WIDTH - 1) of std_logic_vector(15 downto 0);
    signal sram: sram_t;    
begin
    process(all)
    begin
        if falling_edge(we_n) then
            dio <= (others => 'Z');
        end if;
        
        if rising_edge(we_n) then
            sram(to_integer(unsigned(addr(ADDR_WIDTH - 1 downto 0)))) <= dio;
        elsif falling_edge(oe_n) then
            dio <= sram(to_integer(unsigned(addr(ADDR_WIDTH - 1 downto 0)))) after 12 ns;
        end if;
    end process;
end architecture;
