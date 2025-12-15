library ieee;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity image_generator_tb is
end entity;

architecture behavioral of image_generator_tb is
    constant CLK_FREQ  : positive := 50_000_000;
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);
    
    -- DUT constants
    constant WIDTH_PX   : positive := 3;
    constant HEIGHT_PX  : positive := 3;
    constant X_START_PX : positive := 3; -- 159;
    constant Y_START_PX : positive := 1; -- 80;    

    -- DUT signals
    constant ADDR_WIDTH : integer := integer(ceil(log2(real(WIDTH_PX * HEIGHT_PX))));    

    signal clk          : std_logic := '0';
    signal rst          : std_logic;
    signal pixel_ce     : std_logic;    
    signal pixel_x      : std_logic_vector(9 downto 0);
    signal pixel_y      : std_logic_vector(9 downto 0);
    signal vram_addr    : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal vram_dout    : std_logic;
    signal refresh_tick : std_logic;    
    signal red          : std_logic;
    signal green        : std_logic;
    signal blue         : std_logic;

    -- VRAM mock
    type vram_t is array(0 to 2**ADDR_WIDTH - 1) of std_logic;    
    signal vram: vram_t  := (
        0      => '1',
        2      => '1',
        4      => '1',
        6      => '1',
        8      => '1',
        others => '0'
    );
    signal vram_addr_reg: std_logic_vector(ADDR_WIDTH - 1 downto 0);
begin
    dut: entity work.image_generator
        generic map (
            WIDTH_PX   => WIDTH_PX,
            HEIGHT_PX  => HEIGHT_PX,    
            X_START_PX => X_START_PX,
            Y_START_PX => Y_START_PX
        )        
        port map (
            clk          => clk,
            rst          => rst,
            pixel_ce     => pixel_ce,
            pixel_x      => pixel_x,
            pixel_y      => pixel_y,
            vram_dout    => vram_dout,
            vram_addr    => vram_addr,
            refresh_tick => refresh_tick,
            red          => red,
            green        => green,
            blue         => blue
        );

    clk <= not clk after CLK_PERIOD / 2;
    
    process
        procedure set_pixel(x: integer; y: integer) is
        begin
            wait until rising_edge(clk) and pixel_ce = '1';            
            pixel_x <= std_logic_vector(to_unsigned(x, pixel_x'length));
            pixel_y <= std_logic_vector(to_unsigned(y, pixel_y'length));
        end procedure;
    begin
        pixel_x <= (others => '0');
        pixel_y <= (others => '0');
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '1';

        for y in 0 to 479 loop
            for x in 0 to 639 loop
                set_pixel(x, y);   
            end loop;
        end loop;
        
        wait;
    end process;

    -- VRAM mock
    process(clk)
    begin
        if rising_edge(clk) then
            vram_addr_reg <= vram_addr;
        end if;
    end process;
    
    vram_dout <= vram(to_integer(unsigned(vram_addr_reg)));
    
    -- Pixel ce
    process(clk, rst)
    begin
        if rst then
            pixel_ce <= '0';
        elsif rising_edge(clk) then
            pixel_ce <= not pixel_ce;
        end if;
    end process;    
end architecture;
