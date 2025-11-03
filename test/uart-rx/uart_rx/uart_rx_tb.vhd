library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx_tb is
end entity;

architecture behavioral of uart_rx_tb is
    -- DUT generics
    constant CLK_FREQ  : positive := 50_000_000;
    constant BAUD_RATE : positive := 115_200;

    -- Derived constants
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);
    constant BIT_PERIOD : time := 1 sec / real(BAUD_RATE);

    -- Benchmarking signals
    signal baud_clk: std_logic;
    
    -- DUT ports
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal rx        : std_logic := '1';
    signal rx_read   : std_logic := '0';
    signal rx_buffer : std_logic_vector(7 downto 0);
    signal rx_empty  : std_logic;
begin
    dut: entity work.uart_rx
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
            )
        port map (
            clk       => clk,
            rst       => rst,
            rx        => rx,
            rx_read   => rx_read,
            rx_buffer => rx_buffer,
            rx_empty  => rx_empty
            );
    
    clk <= not clk after CLK_PERIOD / 2;
    rst <= '1', '0' after 2 * CLK_PERIOD;
    
    -- Stimulus
    stim_proc: process
        procedure send_byte(b : in std_logic_vector(7 downto 0)) is
        begin
            -- Start bit
            rx <= '0';
            wait for BIT_PERIOD;

            -- Data bits (LSB first)
            for i in 0 to 7 loop
                rx <= b(i);
                wait for BIT_PERIOD;
            end loop;

            -- Stop bit
            rx <= '1';
            wait for BIT_PERIOD;
        end procedure;
    begin
        wait until rst = '0';
        
        wait for 5 * CLK_PERIOD;
        send_byte(b"1010_1010");
        
        wait for 5 * BIT_PERIOD;
        send_byte(b"0000_1111");
        
        wait;        
    end process;
    
    -- Baud clock. NOTE: for benchmark comparison
    process
    begin
        wait until rst = '0';
        
        loop
            wait until rx = '0';
            
            for i in 0 to 9 loop
                baud_clk <= '1';
                wait for BIT_PERIOD / 2;
                baud_clk <= '0';
                wait for BIT_PERIOD / 2;
            end loop;      
        end loop;
    end process;    
end architecture;
