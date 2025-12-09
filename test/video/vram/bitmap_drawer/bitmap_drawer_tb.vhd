library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity bitmap_drawer_tb is
end entity;

architecture behavioral of bitmap_drawer_tb is
    constant CLK_FREQ   : positive := 50_000_000;    
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);

    constant WIDTH_PX   : integer  := 320;
    constant HEIGHT_PX  : integer  := 320;
    constant ADDR_WIDTH : positive := integer(ceil(log2(real(WIDTH_PX * HEIGHT_PX))));
    constant DATA_WIDTH : positive := 9;
    
    signal clk       : std_logic := '0';
    signal rst       : std_logic;
    signal we        : std_logic;
    signal x         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal vram_we   : std_logic;
    signal vram_addr : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal vram_din  : std_logic;

    constant ZERO    : std_logic_vector(x'range) := (others => '0');
    constant ONE     : std_logic_vector(x'range) := std_logic_vector(to_signed(2**(DATA_WIDTH - 1) - 1, x'length));
    constant NEG_ONE : std_logic_vector(x'range) := std_logic_vector(to_signed(-2**(DATA_WIDTH - 1), x'length));

begin
    dut: entity work.bitmap_drawer
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            WIDTH_PX   => WIDTH_PX,
            HEIGHT_PX  => HEIGHT_PX
        )
        port map (
            clk       => clk,
            rst       => rst,
            we        => we,
            x         => x,
            y         => y,
            vram_we   => vram_we,
            vram_addr => vram_addr,
            vram_din  => vram_din
        );

    clk <= not clk after CLK_PERIOD / 2;
    
    process
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '0';
        wait until rising_edge(clk);
        
        -- Write upper left corner: (x, y) = (-1, 1)
        wait until rising_edge(clk);
        we <= '1';
        x  <= NEG_ONE;
        y  <= ONE;

        wait until rising_edge(clk);        
        we <= '0';
        
        wait until rising_edge(clk);
        assert vram_addr =  std_logic_vector(to_unsigned(0, vram_addr'length))
            report "Pixel address mismatch, expected: 0, actual: " & integer'image(to_integer(unsigned(vram_addr)))
            severity error;
            
        -- Write middle of first row: (x, y) = (0, 1)        
        wait until rising_edge(clk);
        we <= '1';
        x  <= ZERO;
        y  <= ONE;

        wait until rising_edge(clk);        
        we <= '0';  
        
        -- Write upper right corner: (x, y) = (1, 1)
        wait until rising_edge(clk);
        we <= '1';
        x  <= ONE;
        y  <= ONE;

        wait until rising_edge(clk);
        we <= '0';

        wait until rising_edge(clk);        
        assert vram_addr = std_logic_vector(to_unsigned(WIDTH_PX - 1, vram_addr'length))
            report "Pixel address mismatch, expected: " & integer'image(WIDTH_PX - 1) & ", actual: " & integer'image(to_integer(unsigned(vram_addr)))
            severity error;                
        
        -- Write middle: (x, y) = (0, 0)
        wait until rising_edge(clk);
        we <= '1';
        x  <= ZERO;
        y  <= ZERO;

        wait until rising_edge(clk);        
        we <= '0';
        
        -- Write lower left corner: (x, y) = (-1, -1)
        wait until rising_edge(clk);
        we <= '1';
        x  <= NEG_ONE;
        y  <= NEG_ONE;

        wait until rising_edge(clk);        
        we <= '0';       

        -- Write middle of last row: (x, y) = (0, -1)
        wait until rising_edge(clk);
        we <= '1';
        x  <= ZERO;
        y  <= NEG_ONE;

        wait until rising_edge(clk);        
        we <= '0'; 
        
        -- Write lower right corner: (x, y) = (1, -1)
        wait until rising_edge(clk);
        we <= '1';
        x  <= ONE;
        y  <= NEG_ONE;

        wait until rising_edge(clk);        
        we <= '0';
        
        wait until rising_edge(clk);        
        assert vram_addr = std_logic_vector(to_unsigned(WIDTH_PX * HEIGHT_PX - 1, vram_addr'length))
            report "Pixel address mismatch, expected: " & integer'image(WIDTH_PX * HEIGHT_PX - 1) & ", actual: " & integer'image(to_integer(unsigned(vram_addr)))
            severity error;        
        wait;
    end process;
end architecture;
