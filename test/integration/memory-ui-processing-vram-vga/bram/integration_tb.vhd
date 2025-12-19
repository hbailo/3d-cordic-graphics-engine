library ieee;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
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

    -- SRAM reader
    constant DATA_WIDTH : positive := 9;
    constant DATA_POINTS : positive := 11946;
    constant ADDR_WIDTH  : positive := integer(ceil(log2(real(DATA_POINTS))));
    
    signal x                : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y                : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z                : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal reader_ram_addr  : std_logic_vector(ADDR_WIDTH - 1 downto 0);        
    signal reader_ram_rw    : std_logic;
    signal reader_ram_start : std_logic;        
    signal valid_ram_read   : std_logic;
    
    -- RAM loader
    signal rx_buffer        : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_empty         : std_logic := '0';
    signal rx_read          : std_logic;
    signal ram_loaded       : std_logic;
    signal loader_ram_addr  : std_logic_vector(ADDR_WIDTH - 1 downto 0);    
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
    signal bram_ena  : std_logic;
    signal bram_we   : std_logic;
    signal bram_addr : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal bram_din  : std_logic_vector(31 downto 0);
    signal bram_dout : std_logic_vector(31 downto 0);
    
    constant SRAM_MOCK_ADDR_WIDTH: positive := integer(ceil(log2(real(DATA_POINTS))));

    -- UI
    constant DEBOUNCE_PERIOD_MS : positive := 20;
    constant ANGULAR_VEL_DEG_S  : positive := 45;
    
    signal x_angle         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal x_angle_up_sw   : std_logic := '0';
    signal x_angle_up      : std_logic;
    signal x_angle_down_sw : std_logic := '0';    
    signal x_angle_down    : std_logic;

    signal y_angle         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y_angle_up_sw   : std_logic := '0';
    signal y_angle_up      : std_logic;
    signal y_angle_down_sw : std_logic := '0';    
    signal y_angle_down    : std_logic;
    
    signal z_angle         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z_angle_up_sw   : std_logic := '0';
    signal z_angle_up      : std_logic;
    signal z_angle_down_sw : std_logic := '0';
    signal z_angle_down    : std_logic;
    
    -- Rotator
    signal y_rot      : std_logic_vector(DATA_WIDTH - 1 downto 0);    
    signal z_rot      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid_rot  : std_logic;

    -- Projector
    signal x_2d       : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y_2d       : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid_proj : std_logic;

    -- VGA
    constant REFRESH_RATE      : positive := 60;        
    constant BITMAP_WIDTH_PX   : positive := 320;
    constant BITMAP_HEIGHT_PX  : positive := 320;
    constant BITMAP_X_START_PX : natural  := 160;
    constant BITMAP_Y_START_PX : natural  := 80;
    constant VRAM_ADDR_WIDTH   : integer := integer(ceil(log2(real(BITMAP_WIDTH_PX * BITMAP_HEIGHT_PX))));
    
    signal vram_dout    : std_logic;
    signal vram_r_addr  : std_logic_vector(VRAM_ADDR_WIDTH - 1 downto 0);
    signal refresh_tick : std_logic;
    signal h_sync       : std_logic;
    signal v_sync       : std_logic;
    signal red          : std_logic_vector(0 downto 0);
    signal green        : std_logic_vector(0 downto 0);
    signal blue         : std_logic_vector(0 downto 0);
    
    -- VRAM    
    signal vram_we      : std_logic;
    signal vram_w_addr  : std_logic_vector(VRAM_ADDR_WIDTH - 1 downto 0);
    signal vram_din     : std_logic;
begin
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
            clk       => clk,
            rst       => rst,
            start     => ram_start,
            rw        => ram_rw,
            addr      => ram_addr,
            din       => ram_din,
            dout      => ram_dout,
            ready     => ram_ready,            
            bram_ena  => bram_ena, 
            bram_we   => bram_we,  
            bram_addr => bram_addr,
            bram_din  => bram_din,
            bram_dout => bram_dout
        );

    bram: entity work.bram
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => 32
        )
        port map (
            clk  => clk,
            ena  => bram_ena,
            we   => bram_we,
            addr => bram_addr,
            din  => bram_din,
            dout => bram_dout
        );
    
    --! Rotation angle user interface
    --! X angle up button debouncer       
    x_angle_up_sw_db: entity work.switch_debouncer
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS
        )
        port map (
            clk   => clk,
            rst   => rst,
            sw    => x_angle_up_sw,
            sw_db => x_angle_up
        );
    
    --! X angle down button debouncer           
    x_angle_down_sw_db: entity work.switch_debouncer
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS
        )
        port map (
            clk   => clk,
            rst   => rst,
            sw    => x_angle_down_sw,
            sw_db => x_angle_down
        );

    --! X angle stepper    
    x_angle_stepper: entity work.angle_stepper
        generic map (
            ANGLE_WIDTH       => DATA_WIDTH,
            CLK_FREQ_HZ       => CLK_FREQ_HZ,
            ANGULAR_VEL_DEG_S => ANGULAR_VEL_DEG_S            
        )
        port map (
            clk   => clk,
            rst   => rst,
            up    => x_angle_up,
            down  => x_angle_down,
            angle => x_angle
        );

    --! Y angle up button debouncer             
    y_angle_up_sw_db: entity work.switch_debouncer
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS
        )
        port map (
            clk   => clk,
            rst   => rst,
            sw    => y_angle_up_sw,
            sw_db => y_angle_up
        );

    --! Y angle down button debouncer         
    y_angle_down_sw_db: entity work.switch_debouncer
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS
        )
        port map (
            clk   => clk,
            rst   => rst,
            sw    => y_angle_down_sw,
            sw_db => y_angle_down
        );

    --! Y angle stepper    
    y_angle_stepper: entity work.angle_stepper
        generic map (
            ANGLE_WIDTH       => DATA_WIDTH,
            CLK_FREQ_HZ       => CLK_FREQ_HZ,
            ANGULAR_VEL_DEG_S => ANGULAR_VEL_DEG_S 
        )
        port map (
            clk   => clk,
            rst   => rst,
            up    => y_angle_up,
            down  => y_angle_down,
            angle => y_angle
        );

    --! Z angle up button debouncer     
    z_angle_up_sw_db: entity work.switch_debouncer
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS
        )
        port map (
            clk   => clk,
            rst   => rst,
            sw    => z_angle_up_sw,
            sw_db => z_angle_up
        );

    --! Z angle down button debouncer 
    z_angle_down_sw_db: entity work.switch_debouncer
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS
        )
        port map (
            clk   => clk,
            rst   => rst,
            sw    => z_angle_down_sw,
            sw_db => z_angle_down
        );

    --! Z angle stepper
    z_angle_stepper: entity work.angle_stepper
        generic map (
            ANGLE_WIDTH       => DATA_WIDTH,
            CLK_FREQ_HZ       => CLK_FREQ_HZ,
            ANGULAR_VEL_DEG_S => ANGULAR_VEL_DEG_S 
        )
        port map (
            clk   => clk,
            rst   => rst,
            up    => z_angle_up,
            down  => z_angle_down,
            angle => z_angle
        );
    
    --! 3D rotator
    rotator: entity work.xyz_rotator
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk     => clk,
            rst     => rst,
            start   => valid_ram_read,
            xi      => x,
            yi      => y,
            zi      => z,
            x_angle => x_angle,
            y_angle => y_angle,
            z_angle => z_angle,
            xo      => open,
            yo      => y_rot,
            zo      => z_rot,
            valid   => valid_rot
        );
    
    --! 3D to 2D projector
    x_2d       <= y_rot;
    y_2d       <= z_rot;
    valid_proj <= valid_rot;      

    --! Bitmap clear/draw sequencer
    bitmap_sequencer: entity work.bitmap_sequencer
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            WIDTH_PX   => BITMAP_WIDTH_PX,
            HEIGHT_PX  => BITMAP_HEIGHT_PX
        )
        port map (
            clk       => clk,
            rst       => rst,
            draw      => valid_proj,
            x         => x_2d,
            y         => y_2d,
            clear     => refresh_tick,
            vram_we   => vram_we,
            vram_addr => vram_w_addr,
            vram_din  => vram_din
        );
    
    --! VRAM
    vram: entity work.dual_port_ram
        generic map (
            ADDR_WIDTH => VRAM_ADDR_WIDTH,
            DATA_WIDTH => 1
        )
        port map (
            clk       => clk,
            we        => vram_we,
            addr_a    => vram_w_addr,
            addr_b    => vram_r_addr,
            din_a     => (0 => vram_din),
            dout_a    => open,
            dout_b(0) => vram_dout
        );

    --! VGA
    vga: entity work.vga
        generic map (
            REFRESH_RATE      => REFRESH_RATE,            
            BITMAP_WIDTH_PX   => BITMAP_WIDTH_PX,
            BITMAP_HEIGHT_PX  => BITMAP_HEIGHT_PX, 
            BITMAP_X_START_PX => BITMAP_X_START_PX,
            BITMAP_Y_START_PX => BITMAP_Y_START_PX
        )
        port map (
            clk          => clk,
            rst          => rst,
            vram_addr    => vram_r_addr,            
            vram_dout    => vram_dout,
            refresh_tick => refresh_tick,
            h_sync       => h_sync,
            v_sync       => v_sync,
            red          => red(0),
            green        => green(0),
            blue         => blue(0)
        );
    
    clk <= not clk after CLK_PERIOD / 2;
    
    -- Memory load
    load_ram: process
        procedure push_rx_byte(byte: std_logic_vector(7 downto 0)) is
        begin
            wait until rising_edge(clk);
            rx_empty  <= '0';            
            rx_buffer <= byte;
            
            wait until rx_read = '1' and rising_edge(clk);
            
            rx_empty <= '1';
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
                        
            push_rx_byte(data_buf(31 downto 24));            
            push_rx_byte(data_buf(23 downto 16));
            push_rx_byte(data_buf(15 downto 8));
            push_rx_byte(data_buf(7 downto 0));
        end loop;
        
        wait;
    end process;

    -- UI simulation
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
        file dump_file   : text open write_mode is BASE_PATH & "/test/integration/memory-ui-processing-vram-vga/bram/build/vga_dump.txt";
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
