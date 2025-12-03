library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity orthographic_projector_tb is
end entity;

architecture behavioral of orthographic_projector_tb is
    constant CLK_FREQ_HZ : positive := 50_000_000;
    constant CLK_PERIOD  : time     := 1 sec / CLK_FREQ_HZ;
    
    constant DATA_WIDTH : positive := 9;
    
    -- DUT signals
    signal clk   : std_logic := '0';
    signal rst   : std_logic;
    signal start : std_logic;
    signal xi    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal yi    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal zi    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal x     : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y     : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid : std_logic; 
begin
    dut: entity work.orthographic_projector
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk   => clk,
            rst   => rst,
            start => start,
            xi    => xi,
            yi    => yi,
            zi    => zi,
            x     => x,
            y     => y,
            valid => valid
        );

    clk <= not clk after CLK_PERIOD / 2;
    
    process
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '1';

        wait until rising_edge(clk);
        start <= '1';
        xi    <= std_logic_vector(to_signed(99, DATA_WIDTH));
        yi    <= std_logic_vector(to_signed(-33, DATA_WIDTH));
        zi    <= std_logic_vector(to_signed(214, DATA_WIDTH));
        
        wait;
    end process;
end architecture;
