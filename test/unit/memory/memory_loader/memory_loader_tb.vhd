library ieee;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity memory_loader_tb is
end entity;

architecture behavioral of memory_loader_tb is
    -- DUT generics
    constant DATA_POINTS : positive := 2;
    constant ADDR_WIDTH  : positive := integer(ceil(log2(real(DATA_POINTS))));
    
    -- DUT signals
    signal clk       : std_logic := '0';
    signal rst       : std_logic;
    signal rx_buffer : std_logic_vector(7 downto 0);
    signal rx_empty  : std_logic;
    signal rx_read   : std_logic;
    signal ram_ready : std_logic;
    signal ram_addr  : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal ram_din   : std_logic_vector(31 downto 0);
    signal ram_start : std_logic;
    signal ram_rw    : std_logic;
    signal loaded    : std_logic;
    
    -- Testbench constants
    constant CLK_FREQ   : positive := 50_000_000;
    constant CLK_PERIOD : time     := 1 sec / real(CLK_FREQ);        
begin
    dut: entity work.memory_loader
        generic map (
            DATA_POINTS => DATA_POINTS
        )
        port map (
            clk       => clk,
            rst       => rst,
            rx_buffer => rx_buffer,
            rx_empty  => rx_empty,
            rx_read   => rx_read,
            ram_ready => ram_ready,
            ram_addr  => ram_addr,
            ram_din   => ram_din,
            ram_start => ram_start,
            ram_rw    => ram_rw,
            loaded    => loaded
        );

    clk <= not clk after CLK_PERIOD / 2;

    --! Stimulus
    process
        procedure push_rx_byte(byte: std_logic_vector(7 downto 0)) is
        begin
            wait until rising_edge(clk);
            rx_empty  <= '0';            
            rx_buffer <= byte;
            
            wait until rx_read = '1' and rising_edge(clk);
            
            rx_empty <= '1';
        end procedure;      
    begin
        rst        <= '1', '0' after CLK_PERIOD / 4;        
        rx_buffer  <= (others => '0');
        wait until rst = '0';
        
        wait until rising_edge(clk);
        
        push_rx_byte(x"AA");
        push_rx_byte(x"BB");
        push_rx_byte(x"CC");
        push_rx_byte(x"DD");

        wait for 4 * CLK_PERIOD;
        
        push_rx_byte(x"EE");
        push_rx_byte(x"FF");
        push_rx_byte(x"AA");
        push_rx_byte(x"BB");
        
        wait;
    end process;

    --! RAM controller mock
    process(clk, rst)
    begin
        if rst then
            ram_ready <= '1';
        elsif rising_edge(clk) then
            if ram_start then
                ram_ready <= '0', '1' after 2 * CLK_PERIOD + 1 fs;
            end if;
        end if;
    end process;
end architecture;
