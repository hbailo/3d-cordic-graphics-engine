library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity cordic_tb is
end entity;

architecture behavioral of cordic_tb is
    constant CLK_FREQ_HZ : positive := 50_000_000;
    constant CLK_PERIOD  : time     := 1 sec / CLK_FREQ_HZ;
    
    constant DATA_WIDTH : positive := 9;

    signal clk   : std_logic := '0';
    signal rst   : std_logic;
    signal start : std_logic;
    signal xi    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal yi    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal zi    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal xo    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal yo    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal zo    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid : std_logic;
begin
    dut: entity work.cordic
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
            xo    => xo,
            yo    => yo,
            zo    => zo,
            valid => valid
        );
    
    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '1';

        -- Case 1: valid input
        wait until rising_edge(clk);
        start <= '1';
        xi <= std_logic_vector(to_signed(99, DATA_WIDTH));
        yi <= std_logic_vector(to_signed(-33, DATA_WIDTH));
        zi <= std_logic_vector(to_signed(-2**(DATA_WIDTH - 2) + 31, DATA_WIDTH));

        -- Case 2: invalid input
        wait until rising_edge(clk);
        start <= '0';
        xi <= (others =>'U');
        yi <= (others =>'U');
        zi <= (others =>'U');

        -- Case 3: valid input
        wait until rising_edge(clk);
        start <= '1';
        xi <= std_logic_vector(to_signed(128, DATA_WIDTH));
        yi <= std_logic_vector(to_signed(-128, DATA_WIDTH));
        zi <= std_logic_vector(to_signed(-2**(DATA_WIDTH - 1), DATA_WIDTH));

        -- Case 4: invalid input
        wait until rising_edge(clk);
        start <= '0';
        xi <= (others =>'U');
        yi <= (others =>'U');
        zi <= (others =>'U');

        -- Case 5: valid input
        wait until rising_edge(clk);
        start <= '1';
        xi <= (others =>'0');
        yi <= (others =>'0');
        zi <= (others =>'0');        

        wait;
    end process;
end architecture;
