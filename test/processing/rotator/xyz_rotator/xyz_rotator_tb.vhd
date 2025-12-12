library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity xyz_rotator_tb is
end entity;

architecture behavioral of xyz_rotator_tb is
    constant CLK_FREQ_HZ : positive := 50_000_000;
    constant CLK_PERIOD  : time     := 1 sec / CLK_FREQ_HZ;
    
    constant DATA_WIDTH : positive := 9;
    
    -- DUT signals
    signal clk     : std_logic := '0';
    signal rst     : std_logic;
    signal start   : std_logic;
    signal xi      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal yi      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal zi      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal x_angle : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y_angle : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z_angle : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal xo      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal yo      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal zo      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid   : std_logic;
begin
    dut: entity work.xyz_rotator
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk     => clk,
            rst     => rst,
            start   => start,
            xi      => xi,
            yi      => yi,
            zi      => zi,
            x_angle => x_angle,
            y_angle => y_angle,
            z_angle => z_angle,
            xo      => xo,
            yo      => yo,
            zo      => zo,
            valid   => valid
        );

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '1';

        wait until rising_edge(clk);
        start   <= '1';
        xi      <= std_logic_vector(to_signed(99, DATA_WIDTH));
        yi      <= std_logic_vector(to_signed(-33, DATA_WIDTH));
        zi      <= std_logic_vector(to_signed(214, DATA_WIDTH));        
        x_angle <= std_logic_vector(to_signed(227, DATA_WIDTH));
        y_angle <= std_logic_vector(to_signed(100, DATA_WIDTH));
        z_angle <= std_logic_vector(to_signed(-21, DATA_WIDTH));
        
        wait until rising_edge(clk);
        start <= '0';
        
        wait until rising_edge(clk);
        start   <= '1';        
        xi      <= std_logic_vector(to_signed(10, DATA_WIDTH));
        yi      <= std_logic_vector(to_signed(-98, DATA_WIDTH));
        zi      <= std_logic_vector(to_signed(201, DATA_WIDTH));
        x_angle <= std_logic_vector(to_signed(2**(DATA_WIDTH - 3), DATA_WIDTH));
        y_angle <= std_logic_vector(to_signed(-2**(DATA_WIDTH - 3), DATA_WIDTH));
        z_angle <= std_logic_vector(to_signed(2**(DATA_WIDTH - 4), DATA_WIDTH));

        wait until rising_edge(clk);
        wait until rising_edge(clk);        
        start <= '0';
        
        wait;
    end process;
end architecture;
