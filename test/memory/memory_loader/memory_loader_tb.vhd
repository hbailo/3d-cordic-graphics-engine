library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory_loader_tb is
end entity;

architecture behavioral of memory_loader_tb is    
    constant CLK_FREQ : positive := 50_000_000;
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);    

    constant DATA_POINTS : positive := 2;
    
    signal clk        : std_logic := '0';
    signal rst        : std_logic;
    signal uart_data  : std_logic_vector(7 downto 0);
    signal uart_empty : std_logic;
    signal uart_read  : std_logic;
    signal sram_ready : std_logic;
    signal sram_addr  : std_logic_vector(17 downto 0);
    signal sram_data  : std_logic_vector(31 downto 0);
    signal sram_start : std_logic;
    signal sram_rw    : std_logic;
    signal loaded     : std_logic;
begin
    dut: entity work.memory_loader
        generic map (
            DATA_POINTS => DATA_POINTS
        )
        port map (
            clk        => clk,
            rst        => rst,
            uart_data  => uart_data,
            uart_empty => uart_empty,
            uart_read  => uart_read,
            sram_ready => sram_ready,
            sram_addr  => sram_addr,
            sram_data  => sram_data,
            sram_start => sram_start,
            sram_rw    => sram_rw,
            loaded     => loaded
        );

    clk <= not clk after CLK_PERIOD / 2;
    
    process
        procedure send_byte(b: std_logic_vector(7 downto 0)) is
        begin
            wait until rising_edge(clk);
            uart_data  <= b;
            uart_empty <= '0';
            wait until uart_read = '1';
            wait until rising_edge(clk);
            uart_empty <= '1';
        end procedure;      
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;        
        uart_data  <= (others => '0');
        wait until rst = '0';
        
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        
        send_byte(x"AA");
        wait until rising_edge(clk);
        
        send_byte(x"BB");
        wait until rising_edge(clk);
        
        send_byte(x"CC");
        wait until rising_edge(clk);
        
        send_byte(x"DD");
        wait until rising_edge(clk);

        wait for 80 ns;
        
        send_byte(x"EE");
        wait until rising_edge(clk);
        
        send_byte(x"FF");
        wait until rising_edge(clk);
        
        send_byte(x"AA");
        wait until rising_edge(clk);
        
        send_byte(x"BB");
        wait until rising_edge(clk);
        
        wait;
    end process;

    --! SRAM controller mock
    process(clk, rst)
    begin
        if rst then
            sram_ready <= '1';
        elsif rising_edge(clk) then
            if sram_start then
                sram_ready <= '0', '1' after 2 * CLK_PERIOD + 1 fs;
            end if;
        end if;
    end process;
end architecture;
