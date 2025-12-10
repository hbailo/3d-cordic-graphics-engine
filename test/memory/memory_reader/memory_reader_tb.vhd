library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory_reader_tb is
end entity;

architecture behavioral of memory_reader_tb is
    -- DUT generics
    constant DATA_POINTS : positive := 4;
    constant DATA_WIDTH  : positive := 9;
    
    -- DUT signals
    signal clk        : std_logic := '0';
    signal rst        : std_logic;
    signal start      : std_logic;
    signal sram_ready : std_logic;
    signal sram_dout  : std_logic_vector(31 downto 0);    
    signal sram_addr  : std_logic_vector(17 downto 0);
    signal sram_start : std_logic;
    signal sram_rw    : std_logic;
    signal x          : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y          : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z          : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid      : std_logic;

    -- Testbench constants
    constant CLK_FREQ   : positive := 50_000_000;    
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);        
begin
    dut: entity work.memory_reader
        generic map (
            DATA_POINTS => DATA_POINTS,
            DATA_WIDTH  => DATA_WIDTH
        )
        port map (
            clk        => clk,
            rst        => rst,
            start      => start,
            sram_ready => sram_ready,
            sram_dout  => sram_dout,            
            sram_addr  => sram_addr,
            sram_start => sram_start,
            sram_rw    => sram_rw,
            x          => x,
            y          => y,
            z          => z,
            valid      => valid
        );

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;        
        wait until rst = '0';
        
        wait until rising_edge(clk);
        start <= '1';
        
        wait;
    end process;

    process(clk, rst)
    begin
        if rst then
            sram_ready <= '1';
            sram_dout  <= (others => '0');            
        elsif rising_edge(clk) then
            if sram_start then
                sram_ready <= '0', '1' after 2 * CLK_PERIOD + 1 fs;
                sram_dout  <= std_logic_vector(unsigned(sram_dout) + b"11111111_11001100_11001110_10101100") after 2 * CLK_PERIOD + 1 fs;
            end if;
        end if;
    end process;
end architecture;
