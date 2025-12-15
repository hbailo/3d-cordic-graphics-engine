library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity dual_port_ram_tb is
end entity;

architecture behavioral of dual_port_ram_tb is
    -- DUT generics
    constant CLK_FREQ: positive := 50_000_000;
    constant CLK_PERIOD: time := 1 sec / real(CLK_FREQ);
    
    -- Test parameters
    constant ADDR_WIDTH: integer := 3;
    constant DATA_WIDTH: integer := 8;

    -- DUT signals
    signal clk     : std_logic := '0';
    signal we      : std_logic := '0';
    signal addr_a  : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal addr_b  : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal din_a   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal dout_a  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal dout_b  : std_logic_vector(DATA_WIDTH-1 downto 0);
begin
    dut: entity work.dual_port_ram
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk     => clk,
            we      => we,
            addr_a  => addr_a,
            addr_b  => addr_b,
            din_a   => din_a,
            dout_a  => dout_a,
            dout_b  => dout_b
        );

    clk <= not clk after CLK_PERIOD / 2;

    stim: process
    begin
        -- Simultaneous Read/Write Tests
        addr_a <= "011";
        din_a  <= x"AB";        
        we     <= '1';
        addr_b <= "011";        
        wait until rising_edge(clk);

        we <= '0';
        wait until rising_edge(clk);

        assert dout_a = x"AB"
            report "Port A wrong after write"
            severity error;

        assert dout_b = x"AB"
            report "Port B wrong after write"
            severity error;

        -- Read/Write different addresses test
        addr_a <= "101";
        din_a  <= x"55";
        we     <= '1';        
        addr_b <= "111";
        wait until rising_edge(clk);

        we <= '0';
        wait until rising_edge(clk);
        
        assert dout_a = x"55"
            report "Port A wrong after write"
            severity error;
        wait;
    end process;
end architecture;
