library ieee;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use std.textio.all;

entity integration_tb is
end entity;

architecture behavioral of integration_tb is
    constant CLK_FREQ_HZ : positive := 50_000_000;
    constant CLK_PERIOD  : time := 1 sec / real(CLK_FREQ_HZ);

    signal clk: std_logic := '0';
    signal rst: std_logic;

    -- SRAM reader
    constant DATA_WIDTH : positive := 9;
    
    signal x                 : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y                 : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z                 : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal reader_sram_addr  : std_logic_vector(17 downto 0);        
    signal reader_sram_rw    : std_logic;
    signal reader_sram_start : std_logic;        
    signal valid_sram_read   : std_logic;
    
    -- SRAM loader
    constant DATA_POINTS : positive := 11946;

    signal rx_buffer         : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_empty          : std_logic := '0';
    signal rx_read           : std_logic;
    signal sram_loaded       : std_logic;
    signal loader_sram_addr  : std_logic_vector(17 downto 0);    
    signal loader_sram_rw    : std_logic;
    signal loader_sram_start : std_logic;
    
    -- SRAM controller
    signal sram_start : std_logic;
    signal sram_rw    : std_logic;
    signal sram_addr  : std_logic_vector(17 downto 0);
    signal sram_din   : std_logic_vector(31 downto 0);
    signal sram_dout  : std_logic_vector(31 downto 0);
    signal sram_ready : std_logic;
    
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
    
    -- Rotator
    signal x_angle    : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal y_angle    : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal z_angle    : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal x_rot      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y_rot      : std_logic_vector(DATA_WIDTH - 1 downto 0);    
    signal z_rot      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid_rot  : std_logic;

    -- Projector
    signal y_proj     : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z_proj     : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid_proj : std_logic;

    -- VGA
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
    signal red          : std_logic;
    signal green        : std_logic;
    signal blue         : std_logic;
    
    -- VRAM    
    signal vram_we      : std_logic;
    signal vram_w_addr  : std_logic_vector(VRAM_ADDR_WIDTH - 1 downto 0);
    signal vram_din     : std_logic;
begin
    memory_loader: entity work.memory_loader
        generic map (
            DATA_POINTS => DATA_POINTS
        )
        port map (
            clk        => clk,
            rst        => rst,
            rx_buffer  => rx_buffer,
            rx_empty   => rx_empty,
            rx_read    => rx_read,
            sram_ready => sram_ready,
            sram_addr  => loader_sram_addr,
            sram_din   => sram_din,
            sram_start => loader_sram_start,
            sram_rw    => loader_sram_rw,
            loaded     => sram_loaded
        );

    memory_reader: entity work.memory_reader
        generic map (
            DATA_POINTS => DATA_POINTS,
            DATA_WIDTH  => DATA_WIDTH
        )
        port map (
            clk        => clk,
            rst        => rst,
            start      => sram_loaded,
            sram_ready => sram_ready,
            sram_dout  => sram_dout,            
            sram_addr  => reader_sram_addr,
            sram_start => reader_sram_start,
            sram_rw    => reader_sram_rw,
            x          => x,
            y          => y,
            z          => z,
            valid      => valid_sram_read
        );

    --! Memory loader / reader mux
    process(all)
    begin
        if sram_loaded = '1' then
            sram_addr  <= reader_sram_addr;            
            sram_start <= reader_sram_start;
            sram_rw    <= reader_sram_rw;
        else
            sram_addr  <= loader_sram_addr;                        
            sram_start <= loader_sram_start;            
            sram_rw    <= loader_sram_rw;
        end if;
    end process;
    
    sram_controller: entity work.sram_controller
        port map (
            clk    => clk,
            rst    => rst,
            start  => sram_start,
            rw     => sram_rw,
            addr   => sram_addr,
            din    => sram_din,
            dout   => sram_dout,
            ready  => sram_ready,            
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

    --! 3D rotator
    rotator: entity work.xyz_rotator
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk     => clk,
            rst     => rst,
            start   => valid_sram_read,
            xi      => x,
            yi      => y,
            zi      => z,
            x_angle => x_angle,
            y_angle => y_angle,
            z_angle => z_angle,
            xo      => x_rot,
            yo      => y_rot,
            zo      => z_rot,
            valid   => valid_rot
        );
    
    --! 3D to 2D projector
    projector: entity work.orthographic_projector
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk   => clk,
            rst   => rst,
            start => valid_rot,
            xi    => x_rot,
            yi    => y_rot,
            zi    => z_rot,
            yo    => y_proj,
            zo    => z_proj,
            valid => valid_proj
        );     

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
            x         => y_proj,
            y         => z_proj,
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
        
        file coord_file : text open read_mode is "../../resources/data/q0.8-coordinates.csv";
        variable L     : line;
        variable vx    : integer;
        variable vy    : integer;
        variable vz    : integer;
        variable dummy : string(1 to 1);
        variable data_buf : std_logic_vector(31 downto 0);
    begin
        rst       <= '1', '0' after CLK_PERIOD / 4;
        rx_buffer <= (others => '0');
        rx_empty  <= '1';
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
end architecture;
