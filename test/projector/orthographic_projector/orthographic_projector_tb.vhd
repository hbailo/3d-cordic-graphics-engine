library ieee;
use ieee.std_logic_1164.all;

entity orthographic_projector_tb is
end orthographic_projector_tb;

architecture behavioral of orthographic_projector_tb is
    constant CLK_FREQ: positive := 50_000_000; -- [Hz]
    constant CLK_PERIOD: time := 1 sec / CLK_FREQ;

    signal clk: std_logic := '0';
    signal rst: std_logic;
    signal xi: std_logic_vector(7 downto 0);
    signal yi: std_logic_vector(7 downto 0);
    signal zi: std_logic_vector(7 downto 0);
    signal xo: std_logic_vector(7 downto 0);
    signal yo: std_logic_vector(7 downto 0); 
begin
    dut: entity work.orthographic_projector
        generic map (
            N => 8
        )
        port map (
            clk => clk,
            rst => rst,
            xi  => xi,
            yi  => yi,
            zi  => zi,
            xo  => xo,
            yo  => yo
        );

    clk <= not clk after CLK_PERIOD / 2;
    rst <= '0', '1' after 1 * CLK_PERIOD, '0' after 3 * CLK_PERIOD;
    
    process
    begin
        wait until rst = '1';
        wait until rst = '0';
        
        assert xo = b"0000_0000" report "xo not cleared after reset" severity error;
        assert yo = b"0000_0000" report "yo not cleared after reset" severity error;
        
        xi <= b"0000_0001";
        yi <= b"0000_0010";
        zi <= b"0000_0011";
        wait for CLK_PERIOD;
        
        assert xo = xi report "xo != xi after clk rising_edge" severity error;
        assert yo = yi report "yo != yi after clk rising_edge" severity error; 
    end process;
end behavioral;
