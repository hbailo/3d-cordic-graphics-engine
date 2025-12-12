library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity bitmap_sequencer_tb is
end entity;

architecture behavioral of bitmap_sequencer_tb is
    -- Clock
    constant CLK_FREQ   : positive := 50_000_000;
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);

    -- DUT generics
    constant DATA_WIDTH : integer := 9;
    constant WIDTH_PX   : integer := 4;
    constant HEIGHT_PX  : integer := 4;
    constant ADDR_WIDTH : integer := integer(ceil(log2(real(WIDTH_PX * HEIGHT_PX))));
    
    -- Signals
    signal clk      : std_logic := '0';
    signal rst      : std_logic;
    signal draw     : std_logic;
    signal x        : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y        : std_logic_vector(DATA_WIDTH - 1 downto 0);        
    signal clear    : std_logic;
    signal vram_din : std_logic;
begin
    dut: entity work.bitmap_sequencer
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            WIDTH_PX   => WIDTH_PX,
            HEIGHT_PX  => HEIGHT_PX
        )
        port map (
            clk       => clk,
            rst       => rst,
            draw      => draw,
            x         => x,
            y         => y,
            clear     => clear,
            vram_we   => open,
            vram_addr => open,
            vram_din  => vram_din
        );    

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '0';
        wait until rising_edge(clk);

        -- Idle to clearing
        clear <= '1';
        wait until rising_edge(clk);        
        clear <= '0';
        
        -- While clearing draw signal turns on
        wait until rising_edge(clk);
        draw <= '1';
        x <= std_logic_vector(to_unsigned(3, DATA_WIDTH));
        y <= std_logic_vector(to_unsigned(5, DATA_WIDTH));
        
        wait until vram_din = '1';
        wait until rising_edge(clk);

        -- Drawing to clearing
        clear <= '1';
        wait until rising_edge(clk);        
        clear <= '0';
        
        wait until vram_din = '1';
        
        -- Drawing to idle
        draw <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Idle to drawing
        draw <= '1';
        x <= std_logic_vector(to_signed(-200, DATA_WIDTH));
        y <= std_logic_vector(to_signed(32, DATA_WIDTH));
        wait until rising_edge(clk);
        draw <= '0';
        
        wait;
    end process;
end architecture;
