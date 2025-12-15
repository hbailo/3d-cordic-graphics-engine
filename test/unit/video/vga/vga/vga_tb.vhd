library ieee;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity vga_tb is
end entity;

architecture behavioral of vga_tb is
    constant CLK_FREQ   : positive := 50_000_000;
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);

    -- DUT constants
    constant REFRESH_RATE      : positive := 50;    
    constant BITMAP_WIDTH_PX   : positive := 3;
    constant BITMAP_HEIGHT_PX  : positive := 3;
    constant BITMAP_X_START_PX : natural  := 1;
    constant BITMAP_Y_START_PX : natural  := 0;
    
    -- DUT signals
    constant VRAM_ADDR_WIDTH : integer := integer(ceil(log2(real(BITMAP_WIDTH_PX * BITMAP_HEIGHT_PX))));
    
    signal clk: std_logic := '0';
    signal rst: std_logic;
    signal vram_dout: std_logic;
    signal vram_addr: std_logic_vector(VRAM_ADDR_WIDTH - 1 downto 0);
    signal refresh_tick: std_logic;
    signal h_sync: std_logic;
    signal v_sync: std_logic;
    signal red: std_logic;
    signal green: std_logic;
    signal blue: std_logic;

    -- VRAM mock
    type vram_t is array(0 to 2**VRAM_ADDR_WIDTH - 1) of std_logic;    
    signal vram: vram_t  := (
        0      => '1',
        2      => '1',
        4      => '1',
        6      => '1',
        8      => '1',
        others => '0'
    );
    signal vram_addr_reg: std_logic_vector(VRAM_ADDR_WIDTH - 1 downto 0);
begin
    dut: entity work.vga
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
            vram_addr    => vram_addr,            
            vram_dout    => vram_dout,
            refresh_tick => refresh_tick,
            h_sync       => h_sync,
            v_sync       => v_sync,
            red          => red,
            green        => green,
            blue         => blue
        );

    clk <= not clk  after CLK_PERIOD / 2;
    rst <= '1', '0' after CLK_PERIOD / 4;

    -- VRAM mock
    process(clk)
    begin
        if rising_edge(clk) then
            vram_addr_reg <= vram_addr;
        end if;
    end process;
    
    vram_dout <= vram(to_integer(unsigned(vram_addr_reg)));    
end architecture;
