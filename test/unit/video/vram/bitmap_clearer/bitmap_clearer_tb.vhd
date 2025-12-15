library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity bitmap_clearer_tb is
end entity;

architecture behavioral of bitmap_clearer_tb is
    -- Clock
    constant CLK_FREQ   : positive := 50_000_000;
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);

    -- DUT generics
    constant WIDTH_PX   : integer := 4;
    constant HEIGHT_PX  : integer := 4;
    constant LAST_ADDR  : integer := WIDTH_PX * HEIGHT_PX - 1;    
    constant ADDR_WIDTH : integer := integer(ceil(log2(real(WIDTH_PX * HEIGHT_PX))));
    
    -- Signals
    signal clk       : std_logic := '0';
    signal rst       : std_logic;
    signal start     : std_logic;
    signal vram_we   : std_logic;
    signal vram_addr : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal vram_din  : std_logic;
    signal ready     : std_logic;
begin
    dut: entity work.bitmap_clearer
        generic map (
            WIDTH_PX   => WIDTH_PX,
            HEIGHT_PX  => HEIGHT_PX
        )
        port map (
            clk       => clk,
            rst       => rst,
            start     => start,
            vram_we   => vram_we,
            vram_addr => vram_addr,
            vram_din  => vram_din,
            ready     => ready
        );

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '0';
        wait until rising_edge(clk);

        assert ready = '1'
            report "Ready should be high after reset"
            severity error;

        start <= '1';
        wait until rising_edge(clk);
        start <= '0';

        for i in 0 to LAST_ADDR loop
            wait until rising_edge(clk);
            assert unsigned(vram_addr) = i
                report "vram_addr mismatch at index " & integer'image(i)
                severity error;
            assert ready = '0'
                report "Ready should be low while clearing"
                severity error;
        end loop;

        wait until rising_edge(clk);
        assert ready = '1'
            report "Ready should return high after clearing"
            severity error;

        wait;
    end process;
end architecture;
