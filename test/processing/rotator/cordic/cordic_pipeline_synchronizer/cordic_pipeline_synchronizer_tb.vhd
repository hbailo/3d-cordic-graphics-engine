library ieee;
use ieee.std_logic_1164.all;

entity cordic_pipeline_synchronizer_tb is
end entity;

architecture behavioral of cordic_pipeline_synchronizer_tb is
    constant CLK_FREQ   : positive := 50_000_000;
    constant CLK_PERIOD : time     := 1 sec / CLK_FREQ;
    
    constant PIPELINE_DEPTH : natural := 5;
    
    signal clk   : std_logic := '0';
    signal rst   : std_logic;
    signal start : std_logic := '0';
    signal valid : std_logic;
begin
    dut: entity work.cordic_pipeline_synchronizer
        generic map (
            PIPELINE_DEPTH => PIPELINE_DEPTH
        )
        port map (
            clk   => clk,
            rst   => rst,
            start => start,
            valid => valid
        );
    
    clk <= not clk after CLK_PERIOD / 2;
    
    process
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '0';

        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';
        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';
        wait until rising_edge(clk);
        start <= '0';

        wait;
    end process;
end architecture;
