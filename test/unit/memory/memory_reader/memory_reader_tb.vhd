library ieee;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity memory_reader_tb is
end entity;

architecture behavioral of memory_reader_tb is
    -- DUT generics
    constant DATA_POINTS : positive := 4;
    constant DATA_WIDTH  : positive := 9;
    constant ADDR_WIDTH  : positive := integer(ceil(log2(real(DATA_POINTS))));
    
    -- DUT signals
    signal clk       : std_logic := '0';
    signal rst       : std_logic;
    signal start     : std_logic;
    signal ram_ready : std_logic;
    signal ram_dout  : std_logic_vector(31 downto 0);    
    signal ram_addr  : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal ram_start : std_logic;
    signal ram_rw    : std_logic;
    signal x         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid     : std_logic;

    -- Testbench constants
    constant CLK_FREQ   : positive := 50_000_000;    
    constant CLK_PERIOD : time     := 1 sec / real(CLK_FREQ);        
begin
    dut: entity work.memory_reader
        generic map (
            DATA_POINTS => DATA_POINTS,
            DATA_WIDTH  => DATA_WIDTH
        )
        port map (
            clk       => clk,
            rst       => rst,
            start     => start,
            ram_ready => ram_ready,
            ram_dout  => ram_dout,            
            ram_addr  => ram_addr,
            ram_start => ram_start,
            ram_rw    => ram_rw,
            x         => x,
            y         => y,
            z         => z,
            valid     => valid
        );

    clk <= not clk after CLK_PERIOD / 2;

    -- Stimulus
    process
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;        
        wait until rst = '0';
        
        wait until rising_edge(clk);
        start <= '1';
        
        wait;
    end process;

    -- RAM mock
    process(clk, rst)
    begin
        if rst then
            ram_ready <= '1';
            ram_dout  <= (others => '0');            
        elsif rising_edge(clk) then
            if ram_start then
                ram_ready <= '0', '1' after 2 * CLK_PERIOD + 1 fs;
                ram_dout  <= std_logic_vector(unsigned(ram_dout) + b"11111111_11001100_11001110_10101100") after 2 * CLK_PERIOD + 1 fs;
            end if;
        end if;
    end process;
end architecture;
