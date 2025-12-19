library ieee;
use ieee.std_logic_1164.all;

entity main_bram_vivado is
    port (
        sysclk: in std_logic;
        rst: in std_logic;
        rx: in std_logic;
        x_angle_up_sw: in std_logic;
        y_angle_up_sw: in std_logic;
        z_angle_up_sw: in std_logic;
        h_sync: out std_logic;
        v_sync: out std_logic;
        red: out std_logic;
        green: out std_logic;
        blue: out std_logic
    );
end entity;

architecture behavioral of main_bram_vivado is
    -- Main constants
    constant CLK_FREQ_HZ        : positive := 50_000_000;
    constant BAUD_RATE          : positive := 115_200;    
    constant DATA_POINTS        : positive := 11946;
    constant DATA_WIDTH         : positive := 9;
    constant ANGULAR_VEL_DEG_S  : positive := 45;    
    constant DEBOUNCE_PERIOD_MS : positive := 20;
    constant VGA_REFRESH_RATE   : positive := 50;    
    constant BITMAP_WIDTH_PX    : positive := 320;
    constant BITMAP_HEIGHT_PX   : positive := 320;
    constant BITMAP_X_START_PX  : natural  := 160;
    constant BITMAP_Y_START_PX  : natural  := 80;

    -- Angle down switches vio
    component angle_down_switches_vio
        port (
            clk        : in  std_logic;
            probe_out0 : out std_logic_vector(0 downto 0);
            probe_out1 : out std_logic_vector(0 downto 0);
            probe_out2 : out std_logic_vector(0 downto 0)
        );
    end component;

    signal x_angle_down_sw : std_logic;
    signal y_angle_down_sw : std_logic;    
    signal z_angle_down_sw : std_logic;

    -- ILA
    component ila_0
        port (
            clk    : in std_logic;
            probe0 : in std_logic_vector(0 downto 0);
            probe1 : in std_logic_vector(0 downto 0); 
            probe2 : in std_logic_vector(0 downto 0); 
            probe3 : in std_logic_vector(0 downto 0);
            probe4 : in std_logic_vector(0 downto 0)
        );
    end component;
    
    -- 50 MHz clk generator
    component clk_gen_50mhz
        port (
            clk_in1  : in  std_logic;
            reset    : in  std_logic;            
            clk_out1 : out std_logic;
            locked   : out std_logic
        );
    end component;
    
    signal clk: std_logic;
begin
    clk_gen: clk_gen_50mhz
        port map (
            clk_in1  => sysclk,
            reset    => rst,             
            clk_out1 => clk,
            locked   => open
        );
    
    main_bram: entity work.main_bram
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
            red             => red,
            green           => green,
            blue            => blue            
        );

    vio_angle_down_switches: angle_down_switches_vio
        port map (
            clk           => clk,
            probe_out0(0) => x_angle_down_sw,
            probe_out1(0) => y_angle_down_sw,
            probe_out2(0) => z_angle_down_sw
        );

    ila: ila_0
        port map (
            clk       => clk,
            probe0(0) => h_sync, 
            probe1(0) => v_sync, 
            probe2(0) => red, 
            probe3(0) => green,
            probe4(0) => blue
        );    
end architecture;
