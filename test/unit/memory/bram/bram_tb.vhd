library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use std.env.all;

entity bram_tb is
end entity;

architecture behavioral of bram_tb is
    constant CLK_FREQ   : positive := 50_000_000;
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);

    -- DUT generics
    constant ADDR_WIDTH : positive := 3;
    constant DATA_WIDTH : positive := 32;
    
    -- DUT signals
    signal clk  : std_logic := '0';
    signal ena  : std_logic;
    signal we   : std_logic;
    signal addr : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal din  : std_logic_vector(31 downto 0);
    signal dout : std_logic_vector(31 downto 0);

begin
    dut: entity work.bram
    generic map (
        ADDR_WIDTH => ADDR_WIDTH,
        DATA_WIDTH => DATA_WIDTH
    )
        port map (
            clk  => clk,
            ena  => ena,
            we   => we,
            addr => addr,
            din  => din,
            dout => dout
        );
    
    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        -- Write
        addr <= std_logic_vector(to_unsigned(3, addr'length));
        din  <= std_logic_vector(to_unsigned(28, din'length));
        we   <= '1';
        ena  <= '1';
        wait until rising_edge(clk);
        
        we  <= '0';
        ena <= '0';        
        wait until rising_edge(clk);

        -- Write
        addr <= std_logic_vector(to_unsigned(1, addr'length));
        din  <= std_logic_vector(to_unsigned(10, din'length));
        we   <= '1';
        ena  <= '1';
        wait until rising_edge(clk);
        
        we  <= '0';
        ena <= '0';        
        wait until rising_edge(clk);
        
        -- Read
        addr <= std_logic_vector(to_unsigned(3, addr'length));
        din  <= (others => '0');
        we   <= '0';
        ena  <= '1';
        wait until rising_edge(clk);
        
        ena <= '0';        
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        
        std.env.finish;
        wait;
    end process;
end architecture;
