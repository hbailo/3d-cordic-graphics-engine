library ieee;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use std.textio.all;

entity main_tb is
    generic (
        BASE_PATH: string := ""
    );        
end entity;

architecture behavioral of main_tb is
    -- DUT generics
    constant CLK_FREQ_HZ        : positive := 50_000_000;
    constant BAUD_RATE          : positive := 115_200;    
    constant DATA_POINTS        : positive := 10;
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

    -- VGA
    signal h_sync : std_logic;
    signal v_sync : std_logic;
    signal red    : std_logic_vector(0 downto 0);
    signal green  : std_logic_vector(0 downto 0);
    signal blue   : std_logic_vector(0 downto 0);
    
    -- Testbench constants    
    constant SRAM_MOCK_ADDR_WIDTH : positive := integer(ceil(log2(real(DATA_POINTS))));
    constant CLK_PERIOD           : time := 1 sec / real(CLK_FREQ_HZ);
    constant BIT_PERIOD           : time := 1 sec / real(BAUD_RATE);    
begin
    dut: entity work.main
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
            addr_a          => addr_a,
            dio_a           => dio_a,
            we_n_a          => we_n_a,
            oe_n_a          => oe_n_a,
            ce_n_a          => ce_n_a,
            ub_n_a          => ub_n_a,
            lb_n_a          => lb_n_a,
            addr_b          => addr_b,
            dio_b           => dio_b,
            we_n_b          => we_n_b,
            oe_n_b          => oe_n_b,
            ce_n_b          => ce_n_b,
            ub_n_b          => ub_n_b,
            lb_n_b          => lb_n_b,
            h_sync          => h_sync,
            v_sync          => v_sync,
            red             => red(0),
            green           => green(0),
            blue            => blue(0)            
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
    
    uart_tx: process
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
        
        file coord_file   : text open read_mode is BASE_PATH & "/test/resources/data/q0.8-coordinates.csv";
        variable L        : line;
        variable vx       : integer;
        variable vy       : integer;
        variable vz       : integer;
        variable dummy    : string(1 to 1);
        variable data_buf : std_logic_vector(31 downto 0);
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '1';
        wait until rising_edge(clk);

        -- Load csv file
        readline(coord_file, L);
        
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

    -- VGA dump
    -- RATIONALE: https://ericeastwood.com/blog/vga-simulator-getting-started/
    vga_dump: process(clk)
        file dump_file   : text open write_mode is BASE_PATH & "/test/main/build/vga_dump.txt";
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
