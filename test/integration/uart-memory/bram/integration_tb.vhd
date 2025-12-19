library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;

entity integration_tb is
    generic (
        BASE_PATH: string := ""
    );
end entity;

architecture behavioral of integration_tb is
    constant CLK_FREQ_HZ : positive := 50_000_000;
    constant CLK_PERIOD  : time := 1 sec / real(CLK_FREQ_HZ);
    
    signal clk: std_logic := '0';
    signal rst: std_logic;

    -- UART
    constant BAUD_RATE : positive := 115_200;
    
    signal rx        : std_logic;    
    signal rx_read   : std_logic;
    signal rx_empty  : std_logic;
    signal rx_buffer : std_logic_vector(7 downto 0);
    
    -- SRAM reader
    constant DATA_WIDTH : positive  := 9;
    constant DATA_POINTS : positive := 20;    
    constant ADDR_WIDTH  : positive := integer(ceil(log2(real(DATA_POINTS))));
    
    signal x                : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y                : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z                : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal reader_ram_addr  : std_logic_vector(ADDR_WIDTH - 1  downto 0);        
    signal reader_ram_rw    : std_logic;
    signal reader_ram_start : std_logic;        
    signal valid_ram_read   : std_logic;
    
    -- SRAM loader
    signal ram_loaded       : std_logic;
    signal loader_ram_addr  : std_logic_vector(ADDR_WIDTH - 1  downto 0);    
    signal loader_ram_rw    : std_logic;
    signal loader_ram_start : std_logic;
    

    -- BRAM controller
    signal ram_start : std_logic;
    signal ram_rw    : std_logic;
    signal ram_addr  : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal ram_din   : std_logic_vector(31 downto 0);
    signal ram_dout  : std_logic_vector(31 downto 0);
    signal ram_ready : std_logic;
    
    -- BRAM
    signal en_a   : std_logic;
    signal en_b   : std_logic;
    signal we_a   : std_logic;
    signal addr_a : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal addr_b : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal din_a  : std_logic_vector(31 downto 0);
    signal dout_b : std_logic_vector(31 downto 0);

    -- Testbench constants
    constant BIT_PERIOD     : time     := 1 sec / real(BAUD_RATE);    
begin
    uart_rx: entity work.uart_rx
        generic map (
            CLK_FREQ  => CLK_FREQ_HZ,
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
    
    memory_loader: entity work.memory_loader
        generic map (
            DATA_POINTS => DATA_POINTS,
            ADDR_WIDTH  => loader_ram_addr'length
        )
        port map (
            clk       => clk,
            rst       => rst,
            rx_buffer => rx_buffer,
            rx_empty  => rx_empty,
            rx_read   => rx_read,
            ram_ready => ram_ready,
            ram_addr  => loader_ram_addr,
            ram_din   => ram_din,
            ram_start => loader_ram_start,
            ram_rw    => loader_ram_rw,
            loaded    => ram_loaded
        );

    memory_reader: entity work.memory_reader
        generic map (
            DATA_POINTS => DATA_POINTS,
            DATA_WIDTH  => DATA_WIDTH,
            ADDR_WIDTH  => reader_ram_addr'length            
        )
        port map (
            clk       => clk,
            rst       => rst,
            start     => ram_loaded,
            ram_ready => ram_ready,
            ram_dout  => ram_dout,            
            ram_addr  => reader_ram_addr,
            ram_start => reader_ram_start,
            ram_rw    => reader_ram_rw,
            x         => x,
            y         => y,
            z         => z,
            valid     => valid_ram_read
        );

    --! Memory loader / reader mux
    process(all)
    begin
        if ram_loaded = '1' then
            ram_addr  <= reader_ram_addr;            
            ram_start <= reader_ram_start;
            ram_rw    <= reader_ram_rw;
        else
            ram_addr  <= loader_ram_addr;                        
            ram_start <= loader_ram_start;            
            ram_rw    <= loader_ram_rw;
        end if;
    end process;
    
    bram_controller: entity work.bram_controller
        generic map (
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk    => clk,
            rst    => rst,
            start  => ram_start,
            rw     => ram_rw,
            addr   => ram_addr,
            din    => ram_din,
            dout   => ram_dout,
            ready  => ram_ready,            
            en_a   => en_a,
            en_b   => en_b,
            we_a   => we_a,
            addr_a => addr_a,
            addr_b => addr_b,
            din_a  => din_a,
            dout_b => dout_b
        );

    bram: entity work.bram
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => 32
        )
        port map (
            clk    => clk,
            en_a   => en_a,
            en_b   => en_b,
            we_a   => we_a,
            addr_a => addr_a,
            addr_b => addr_b,
            din_a  => din_a,
            dout_b => dout_b
        );
    
    clk <= not clk after CLK_PERIOD / 2;
    
    uart_tx: process
        procedure push_tx_byte(byte : in std_logic_vector(7 downto 0)) is
        begin
            -- Start bit
            rx <= '0';
            wait for BIT_PERIOD;

            -- Data bits (LSB first)
            for i in 0 to 7 loop
                rx <= byte(i);
                wait for BIT_PERIOD;
            end loop;

            -- Stop bit
            rx <= '1';
            wait for BIT_PERIOD;
        end procedure;
        
        file input_csv    : text open read_mode is BASE_PATH & "/test/resources/data/q0.8-coordinates.csv";
        variable line_buf : line;
        variable x_int    : integer;
        variable y_int    : integer;
        variable z_int    : integer;
        variable comma    : string(1 to 1);
        variable data_buf : std_logic_vector(31 downto 0);
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '1';
        wait until rising_edge(clk);
        
        readline(input_csv, line_buf);
        
        while not endfile(input_csv) loop
            readline(input_csv, line_buf);

            read(line_buf, x_int);
            read(line_buf, comma);
            read(line_buf, y_int);
            read(line_buf, comma);
            read(line_buf, z_int);
 
            data_buf := std_logic_vector(to_signed(x_int, DATA_WIDTH)) &
                        std_logic_vector(to_signed(y_int, DATA_WIDTH)) &
                        std_logic_vector(to_signed(z_int, DATA_WIDTH)) &
                        "00000";
                        
            push_tx_byte(data_buf(31 downto 24));            
            push_tx_byte(data_buf(23 downto 16));
            push_tx_byte(data_buf(15 downto 8));
            push_tx_byte(data_buf(7 downto 0));
        end loop;
        
        wait;
    end process;

    dump_sram: process
        file dump_csv : text open write_mode is BASE_PATH & "/test/integration/uart-memory/bram/build/ram_dump.txt";        
        variable line_buf : line;        
    begin
        wait until ram_loaded = '1';

        -- Write header
        write(line_buf, string'("x,y,z"));
        writeline(dump_csv, line_buf);
        
        for i in 0 to DATA_POINTS - 1 loop
            wait until rising_edge(valid_ram_read);            

            write(line_buf, to_integer(signed(x)));
            write(line_buf, string'(","));                                
            write(line_buf, to_integer(signed(y)));
            write(line_buf, string'(","));                                                
            write(line_buf, to_integer(signed(z)));

            writeline(dump_csv, line_buf);
            line_buf := null;
            
            wait until valid_ram_read = '0';
        end loop;
        
        std.env.finish;
    end process;
end architecture;
