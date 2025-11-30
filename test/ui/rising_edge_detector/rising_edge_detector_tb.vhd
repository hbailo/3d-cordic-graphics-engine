
library ieee;
use ieee.std_logic_1164.all;

entity rising_edge_detector_tb is
end entity;

architecture behavioral of rising_edge_detector_tb is
    constant CLK_FREQ_HZ : positive := 50_000_000;
    constant CLK_PERIOD  : time     := 1 sec / CLK_FREQ_HZ;    
    signal clk   : std_logic := '0';
    signal rst   : std_logic;
    signal din   : std_logic;
    signal pulse : std_logic;
begin
    dut: entity work.rising_edge_detector
        port map (
            clk   => clk,
            rst   => rst,
            din   => din,
            pulse => pulse
        );

    clk <= not clk after CLK_PERIOD / 2;
    
    process
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '0';
        wait until rising_edge(clk);
        
        din <= '0';
        wait until rising_edge(clk);
        din <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);        
        din <= '0';
        
        wait;
    end process;
end architecture;
