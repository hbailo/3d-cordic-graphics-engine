library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity sram_mock_tb is
end entity;

architecture behavioral of sram_mock_tb is
    constant ADDR_WIDTH: positive := 3;

    signal addr: std_logic_vector(17 downto 0);
    signal dio: std_logic_vector(15 downto 0);
    signal ce_n: std_logic;    
    signal we_n: std_logic;
    signal oe_n: std_logic;
    signal ub_n: std_logic;
    signal lb_n: std_logic;
begin
    dut: entity work.sram_mock
        generic map (
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            addr => addr,
            dio  => dio,
            ce_n => ce_n,            
            we_n => we_n,
            oe_n => oe_n,
            ub_n => ub_n,
            lb_n => lb_n
        );

    process
    begin
        ce_n <= '1';        
        we_n <= '1';
        oe_n <= '1';
        ub_n <= '0';
        lb_n <= '0';
        wait for 10 ns;
        
        -- Write
        we_n <= '0';        
        we_n <= '0';
        addr <= std_logic_vector(to_unsigned(2, addr'length));
        dio  <= x"BEEF";
        
        wait for 10 ns;

        we_n <= '1';
        
        wait for 10 ns;
        
        -- Reset
        addr <= (others => '0');
        dio  <= (others => 'Z');
        
        -- Read
        wait for 10 ns;        
        ce_n <= '1';
        we_n <= '1';
        oe_n <= '0';
        addr <= std_logic_vector(to_unsigned(2, addr'length));

        wait for 20 ns;
        oe_n <= '1';        
        addr <= (others => '0');
        dio  <= (others => 'Z');        
        wait;
    end process;
end architecture;
