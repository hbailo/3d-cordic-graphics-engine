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

    -- RAM reader
    constant DATA_WIDTH : positive := 9;
    
    signal x                : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y                : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z                : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal reader_ram_addr  : std_logic_vector(17 downto 0);        
    signal reader_ram_rw    : std_logic;
    signal reader_ram_start : std_logic;        
    signal valid_ram_read   : std_logic;
    
    -- RAM loader
    constant DATA_POINTS : positive := 11946;

    signal rx_buffer         : std_logic_vector(7 downto 0);
    signal rx_empty        : std_logic;
    signal rx_read         : std_logic;
    signal ram_loaded       : std_logic;
    signal loader_ram_addr  : std_logic_vector(17 downto 0);    
    signal loader_ram_rw    : std_logic;
    signal loader_ram_start : std_logic;
    
    -- RAM controller
    signal ram_start : std_logic;
    signal ram_rw    : std_logic;
    signal ram_addr  : std_logic_vector(17 downto 0);
    signal ram_din   : std_logic_vector(31 downto 0);
    signal ram_dout  : std_logic_vector(31 downto 0);
    signal ram_ready : std_logic;
    
    -- SRAM A    
    signal addr_a : std_logic_vector(17 downto 0);
    signal dio_a  : std_logic_vector(15 downto 0);
    signal we_n_a : std_logic;
    signal oe_n_a : std_logic;
    signal ce_n_a : std_logic;
    signal ub_n_a : std_logic;
    signal lb_n_a : std_logic;
    
    -- SRAM B    
    signal addr_b : std_logic_vector(17 downto 0);
    signal dio_b  : std_logic_vector(15 downto 0);
    signal we_n_b : std_logic;
    signal oe_n_b : std_logic;
    signal ce_n_b : std_logic;
    signal ub_n_b : std_logic;
    signal lb_n_b : std_logic;

    constant SRAM_MOCK_ADDR_WIDTH: positive := integer(ceil(log2(real(DATA_POINTS))));      
begin
    memory_loader: entity work.memory_loader
        generic map (
            DATA_POINTS => DATA_POINTS,
            ADDR_WIDTH  => loader_ram_addr'length            
        )
        port map (
            clk        => clk,
            rst        => rst,
            rx_buffer  => rx_buffer,
            rx_empty   => rx_empty,
            rx_read    => rx_read,
            ram_ready  => ram_ready,
            ram_addr   => loader_ram_addr,
            ram_din    => ram_din,
            ram_start  => loader_ram_start,
            ram_rw     => loader_ram_rw,
            loaded     => ram_loaded
        );

    memory_reader: entity work.memory_reader
        generic map (
            DATA_POINTS => DATA_POINTS,
            DATA_WIDTH  => DATA_WIDTH,
            ADDR_WIDTH  => reader_ram_addr'length
        )
        port map (
            clk        => clk,
            rst        => rst,
            start      => ram_loaded,
            ram_ready  => ram_ready,
            ram_dout   => ram_dout,            
            ram_addr   => reader_ram_addr,
            ram_start  => reader_ram_start,
            ram_rw     => reader_ram_rw,
            x          => x,
            y          => y,
            z          => z,
            valid      => valid_ram_read
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
    
    sram_controller: entity work.sram_controller
        port map (
            clk    => clk,
            rst    => rst,
            start  => ram_start,
            rw     => ram_rw,
            addr   => ram_addr,
            din    => ram_din,
            dout   => ram_dout,
            ready  => ram_ready,            
            addr_a => addr_a,
            dio_a  => dio_a,
            we_n_a => we_n_a,
            oe_n_a => oe_n_a,
            ce_n_a => ce_n_a,
            ub_n_a => ub_n_a,
            lb_n_a => lb_n_a,
            addr_b => addr_b,
            dio_b  => dio_b,
            we_n_b => we_n_b,
            oe_n_b => oe_n_b,
            ce_n_b => ce_n_b,
            ub_n_b => ub_n_b,
            lb_n_b => lb_n_b
        );

    sram_a: entity work.sram_mock
        generic map (
            ADDR_WIDTH => SRAM_MOCK_ADDR_WIDTH
        )
        port map (
            addr => addr_a,
            dio  => dio_a,
            we_n => we_n_a,
            oe_n => oe_n_a,
            ce_n => ce_n_a,
            ub_n => ub_n_a,
            lb_n => lb_n_a
        );

    sram_b: entity work.sram_mock
        generic map (
            ADDR_WIDTH => SRAM_MOCK_ADDR_WIDTH
        )        
        port map (
            addr => addr_b,
            dio  => dio_b,
            we_n => we_n_b,
            oe_n => oe_n_b,
            ce_n => ce_n_b,
            ub_n => ub_n_b,
            lb_n => lb_n_b
        );
    
    clk <= not clk after CLK_PERIOD / 2;
    
    load_sram: process
        procedure send_byte(byte: std_logic_vector(7 downto 0)) is
        begin
            wait until rising_edge(clk);
            rx_buffer <= byte;
            rx_empty  <= '0';
            wait until rx_read = '1';
            wait until rising_edge(clk);
            rx_empty <= '1';
        end procedure;
        
        file coord_file : text open read_mode is BASE_PATH & "/test/resources/data/q0.8-coordinates.csv";
        variable L     : line;
        variable vx    : integer;
        variable vy    : integer;
        variable vz    : integer;
        variable dummy : string(1 to 1);
        variable data_buf : std_logic_vector(31 downto 0);
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '1';
        wait until rising_edge(clk);

        -- Load csv file
        readline(coord_file, L); -- Header line
        
        while not endfile(coord_file) loop
            readline(coord_file, L);

            -- Read coordinates x,y,z (comma separated)
            read(L, vx);
            read(L, dummy);  -- comma
            read(L, vy);
            read(L, dummy);  -- comma
            read(L, vz);
 
            data_buf := std_logic_vector(to_signed(vx, DATA_WIDTH)) &
                        std_logic_vector(to_signed(vy, DATA_WIDTH)) &
                        std_logic_vector(to_signed(vz, DATA_WIDTH)) &
                        "00000";
                        
            send_byte(data_buf(31 downto 24));            
            send_byte(data_buf(23 downto 16));
            send_byte(data_buf(15 downto 8));
            send_byte(data_buf(7 downto 0));
        end loop;
        
        wait;
    end process;

    dump_sram: process
        file dump_file : text open write_mode is BASE_PATH & "/test/integration/memory/sram/build/sram_dump.txt";        
        variable L     : line;        
    begin
        wait until ram_loaded = '1';
        
        for i in 0 to DATA_POINTS - 1 loop
            wait until rising_edge(valid_ram_read);            

            write(L, integer(to_integer(signed(x))));
            write(L, string'(","));                                
            write(L, integer(to_integer(signed(y))));
            write(L, string'(","));                                                
            write(L, integer(to_integer(signed(z))));

            writeline(dump_file, L);
            L := null;
            
            wait until valid_ram_read = '0';
        end loop;
        wait;
    end process;
end architecture;
