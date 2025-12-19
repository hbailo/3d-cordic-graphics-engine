library ieee;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use std.textio.all;

entity main_bram_tb is
    generic (
        BASE_PATH: string := ""
    );        
end entity;

architecture behavioral of main_bram_tb is
    -- DUT generics
    constant CLK_FREQ_HZ        : positive := 50_000_000;
    constant BAUD_RATE          : positive := 115_200;    
    constant DATA_POINTS        : positive := 5;
    constant DATA_WIDTH         : positive := 9;
    constant ANGULAR_VEL_DEG_S  : positive := 45;    
    constant DEBOUNCE_PERIOD_MS : positive := 20;
    constant VGA_REFRESH_RATE   : positive := 50;    
    constant BITMAP_WIDTH_PX    : positive := 320;
    constant BITMAP_HEIGHT_PX   : positive := 320;
    constant BITMAP_X_START_PX  : natural  := 160;
    constant BITMAP_Y_START_PX  : natural  := 80;
    
    -- DUT signals
    signal clk : std_logic := '0';
    signal rst : std_logic;

    -- UART RX
    signal rx : std_logic := '1';
    
    -- X angle buttons
    signal x_angle_up_sw   : std_logic := '0';
    signal x_angle_down_sw : std_logic := '0';    

    -- Z angle buttons
    signal y_angle_up_sw   : std_logic := '0';
    signal y_angle_down_sw : std_logic := '0';

    -- Z angle buttons
    signal z_angle_up_sw   : std_logic := '0';
    signal z_angle_down_sw : std_logic := '0';        

    -- VGA
    signal h_sync : std_logic;
    signal v_sync : std_logic;
    signal red    : std_logic_vector(0 downto 0);
    signal green  : std_logic_vector(0 downto 0);
    signal blue   : std_logic_vector(0 downto 0);
    
    -- Testbench constants    
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ_HZ);
    constant BIT_PERIOD : time := 1 sec / real(BAUD_RATE);    
begin
    dut: entity work.main_bram
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            BAUD_RATE          => BAUD_RATE,
            DATA_POINTS        => DATA_POINTS,            
            DATA_WIDTH         => DATA_WIDTH,
            ANGULAR_VEL_DEG_S  => ANGULAR_VEL_DEG_S,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS,
            VGA_REFRESH_RATE   => VGA_REFRESH_RATE,
            BITMAP_WIDTH_PX    => BITMAP_WIDTH_PX,
            BITMAP_HEIGHT_PX   => BITMAP_HEIGHT_PX,
            BITMAP_X_START_PX  => BITMAP_X_START_PX,
            BITMAP_Y_START_PX  => BITMAP_Y_START_PX 
        )
        port map (
            clk             => clk,
            rst             => rst,
            rx              => rx,
            x_angle_up_sw   => x_angle_up_sw,   
            x_angle_down_sw => x_angle_down_sw,
            y_angle_up_sw   => y_angle_up_sw,  
            y_angle_down_sw => y_angle_down_sw,
            z_angle_up_sw   => z_angle_up_sw,  
            z_angle_down_sw => z_angle_down_sw,            
            h_sync          => h_sync,
            v_sync          => v_sync,
            red             => red(0),
            green           => green(0),
            blue            => blue(0)            
        );

    clk <= not clk after CLK_PERIOD / 2;

    -- Uart tx simulation
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

    -- Ui simulation
    ui: process
    begin
        x_angle_up_sw   <= '1' after 10 ms, '0' after 45 ms;
        y_angle_down_sw <= '1' after 20 ms, '0' after 65 ms;
        z_angle_down_sw <= '1' after 30 ms; 
        
        wait;
    end process;
    
    -- VGA dump
    -- RATIONALE: https://ericeastwood.com/blog/vga-simulator-getting-started/
    vga_dump: process(clk)
        file dump_file   : text open write_mode is BASE_PATH & "/test/main/main_bram/build/vga_dump.txt";
        variable line_el : line;
    begin
        if rising_edge(clk) then
            -- Write the time
            write(line_el, now); 
            write(line_el, string'(":"));

            -- Write the hsync
            write(line_el, string'(" "));            
            write(line_el, h_sync);

            -- Write the vsync
            write(line_el, string'(" "));            
            write(line_el, v_sync);

            -- Write the red
            write(line_el, string'(" "));
            write(line_el, std_logic_vector(resize(signed(red), 3)));

            -- Write the green
            write(line_el, string'(" "));
            write(line_el, std_logic_vector(resize(signed(green), 3)));                        

            -- Write the blue
            write(line_el, string'(" "));
            write(line_el, std_logic_vector(resize(signed(blue), 2)));                        

            -- write the contents into the file
            writeline(dump_file, line_el);
        end if;
    end process;    
end architecture;
