--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.math_real.all;
use ieee.std_logic_1164.all;

--! @brief Top-level 3D graphics engine system integrating UART, SRAM, 3D rotator, projector, bitmap, VRAM, and VGA
--! @details
--! Implements the full 3D visualization pipeline:
--! 1. UART receives bytes representing 3D point coordinates.
--! 2. Memory loader and reader manage SRAM banks A/B.
--! 3. User interface allows interactive angular adjustments with debounced switches and angle steppers.
--! 4. 3D rotator applies rotation to points based on user-controlled angles.
--! 5. Orthographic projector maps 3D points to 2D coordinates.
--! 6. Bitmap sequencer writes projected points into VRAM.
--! 7. Dual-port RAM provides VRAM access to both sequencer and VGA controller.
--! 8. VGA entity reads VRAM and generates RGB signals with h_sync and v_sync.
entity main_sram is
    generic (        
        --! System clock frequency in Hz
        CLK_FREQ_HZ: positive := 50_000_000;

        --! UART baud rate in bits per second
        BAUD_RATE: positive := 115_200;

        --! Total number of 32-bit points to load to memory
        DATA_POINTS: positive := 11946;
        
        --! Coordinates and angles bit width        
        DATA_WIDTH: positive := 9;

        --! Maximum angular velocity for stepper-controlled rotations [deg/s]
        ANGULAR_VEL_DEG_S: positive := 45;

        --! Debounce period for user input switches in milliseconds        
        DEBOUNCE_PERIOD_MS: positive := 20;
        
        --! Bitmap width in pixels                
        BITMAP_WIDTH_PX: positive := 320;

        --! Bitmap height in pixels        
        BITMAP_HEIGHT_PX: positive := 320;

        --! Bitmap starting X coordinate        
        BITMAP_X_START_PX: natural range 0 to 640 - BITMAP_WIDTH_PX := 160;

        --! Bitmap starting Y coordinate        
        BITMAP_Y_START_PX: natural range 0 to 480 - BITMAP_HEIGHT_PX := 80 
    );
    
    port (
        --! System clock          
        clk: in std_logic;

        --! Active-high asynchronous reset           
        rst: in std_logic;

        --! UART serial data input line        
        rx: in std_logic;

        --! X angle up switch
        x_angle_up_sw: in std_logic;
        
        --! X angle down switch        
        x_angle_down_sw: in std_logic;
        
        --! Y angle up switch
        y_angle_up_sw: in std_logic;
        
        --! Y angle down switch        
        y_angle_down_sw: in std_logic;
        
        --! Z angle up switch        
        z_angle_up_sw: in std_logic;
        
        --! Z angle down switch                
        z_angle_down_sw: in std_logic;
        
        --! Address bus for SRAM sram A        
        addr_a: out std_logic_vector(17 downto 0);

        --! 16-bit bidirectional data bus for sram A        
        dio_a: inout std_logic_vector(15 downto 0);

        --! Write enable for sram A (active low)        
        we_n_a: out std_logic;
        
        --! Output enable for sram A (active low)        
        oe_n_a: out std_logic;

        --! Chip enable for sram A (active low)        
        ce_n_a: out std_logic;

        --! Upper byte enable for sram A (active low)        
        ub_n_a: out std_logic;
        
        --! Lower byte enable for sram A (active low)        
        lb_n_a: out std_logic;

        --! Address bus for SRAM sram B        
        addr_b: out std_logic_vector(17 downto 0);

        --! 16-bit bidirectional data bus for sram B        
        dio_b: inout std_logic_vector(15 downto 0);

        --! Write enable for sram B (active low)        
        we_n_b: out std_logic;

        --! Output enable for sram B (active low)        
        oe_n_b: out std_logic;

        --! Chip enable for sram B (active low)        
        ce_n_b: out std_logic;

        --! Upper byte enable for sram B (active low)        
        ub_n_b: out std_logic;

        --! Lower byte enable for sram B (active low)        
        lb_n_b: out std_logic;

        --! VGA horizontal sync output                
        h_sync: out std_logic;
        
        --! VGA vertical sync output                        
        v_sync: out std_logic;

        --! VGA red channel output (monochrome)        
        red: out std_logic;
        
        --! VGA green channel output (monochrome)                
        green: out std_logic;
        
        --! VGA blue channel output (monochrome)                        
        blue: out std_logic        
    );
end entity;

--! @brief Structural architecture of main
--! @details
--! Instantiates all submodules:
--! - uart_rx for receiving point data
--! - memory_loader and memory_reader for RAM access
--! - sram_controller for sram multiplexing
--! - switch_debouncer and angle_stepper for user input
--! - xyz_rotator and orthographic_projector for 3D processing
--! - bitmap_sequencer for VRAM writes
--! - dual_port_ram for VRAM
--! - vga for display output
architecture structural of main_sram is
    -- UART
    signal rx_read   : std_logic;
    signal rx_empty  : std_logic;
    signal rx_buffer : std_logic_vector(7 downto 0);
    
    -- RAM reader    
    signal x                : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y                : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z                : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal reader_ram_addr  : std_logic_vector(17 downto 0);        
    signal reader_ram_rw    : std_logic;
    signal reader_ram_start : std_logic;        
    signal valid_ram_read   : std_logic;

    -- RAM loader
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
    
    -- UI
    signal x_angle      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal x_angle_up   : std_logic;
    signal x_angle_down : std_logic;

    signal y_angle      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y_angle_up   : std_logic;
    signal y_angle_down : std_logic;
    
    signal z_angle      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z_angle_up   : std_logic;
    signal z_angle_down : std_logic;

    -- Rotator
    signal y_rot     : std_logic_vector(DATA_WIDTH - 1 downto 0);    
    signal z_rot     : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid_rot : std_logic;

    -- Projector
    signal x_2d       : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y_2d       : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid_proj : std_logic;

    -- VRAM
    constant VRAM_ADDR_WIDTH : integer := integer(ceil(log2(real(BITMAP_WIDTH_PX * BITMAP_HEIGHT_PX))));
    
    signal vram_we     : std_logic;
    signal vram_w_addr : std_logic_vector(VRAM_ADDR_WIDTH - 1 downto 0);
    signal vram_din    : std_logic;
    signal vram_r_addr : std_logic_vector(VRAM_ADDR_WIDTH - 1 downto 0);
    signal vram_dout   : std_logic;

    -- VGA
    signal refresh_tick : std_logic;
begin
    --! Uart rx interface
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

    --! Memory loader
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

    --! Memory reader
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
    
    --! Coordinates memory
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
            red          => red,
            green        => green,
            blue         => blue
        );    
end architecture;
