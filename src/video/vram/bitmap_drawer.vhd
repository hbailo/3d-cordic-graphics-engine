--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

--! @brief Bitmap coordinate-to-address converter and pixel writer
--! @details
--! Converts normalized signed coordinates in the range [-1, 1) into
--! pixel indices within a WIDTH_PX x HEIGHT_PX bitmap and issues the
--! corresponding VRAM write operation.

--! When `we` is asserted, the module generates:
--!   - a VRAM write enable (`vram_we = '1'`)
--!   - the corresponding linear pixel address (`vram_addr`)
--!   - a fixed pixel value (`vram_din = '1'`)
--!
--! Coordinate mapping:
--!   - Input range:    x,y : [-1, 1), in signed Q0.(DATA_WIDTH - 1) fixed point
--!                                    format
--!   - Output range:   x_px : [0, WIDTH_PX )
--!                     y_px : [0, HEIGHT_PX)
--!   - Address:        addr = y_px * WIDTH_PX + x_px
entity bitmap_drawer is
    generic (
        --! Coordinates bit width
        DATA_WIDTH: positive range 1 to 1023;
        
        --! Bitmap width in pixels        
        WIDTH_PX: positive;
        
        --! Bitmap height in pixels
        HEIGHT_PX: positive;

        --! Number of address bits
        ADDR_WIDTH: positive := integer(ceil(log2(real(WIDTH_PX * HEIGHT_PX))))
    );    
    port (
        --! System clock
        clk: in std_logic;

        --! Active-high asynchronous reset
        rst: in std_logic;

        --! Write enable
        we: in std_logic;

        --! x bitmap coordinate
        x: in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! y bitmap coordinate
        y: in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Write enable for VRAM        
        vram_we: out std_logic;

        --! Pixel VRAM address        
        vram_addr: out std_logic_vector(ADDR_WIDTH - 1 downto 0);

        --! Pixel data to be written into VRAM        
        vram_din: out std_logic
    );
end entity;

--! @brief Behavioral architecture of the bitmap drawer
--! @details
--! Implements the full coordinate-to-pixel conversion chain:
--! - Sign-extension of input coordinates
--! - Shifting from [-1,1) to [0,2)
--! - Scaling to bitmap dimensions
--! - Fixed-point truncation to obtain integer pixel locations
--! - Linear address computation for VRAM
--!
--! Write operation:
--! - On rising clock edge, if `we = '1'` then a VRAM write pulse is issued.
architecture behavioral of bitmap_drawer is
    --! @brief Integer ceiling of log2
    --! @details Returns the minimum number of bits required to represent
    --! values in the range [0, n). For n ≤ 1, returns 1.
    function clog2(n: positive) return natural is
    begin
        if n <= 1 then
            return 1;
        else
            return integer(ceil(log2(real(n))));
        end if;
    end function;
    
    --! @brief Signed fixed-point unity in Q1.(DATA_WIDTH - 1) format
    constant ONE: signed(DATA_WIDTH downto 0) := to_signed(2**(DATA_WIDTH - 1), DATA_WIDTH + 1);
    
    constant X_PX_WIDTH: positive := clog2(WIDTH_PX);
    constant Y_PX_WIDTH: positive := clog2(HEIGHT_PX);
    
    signal x_s: signed(DATA_WIDTH downto 0);
    signal y_s: signed(DATA_WIDTH downto 0);
    
    signal x_shifted: unsigned(DATA_WIDTH downto 0);
    signal y_shifted: unsigned(DATA_WIDTH downto 0);
    
    signal x_scaled: unsigned(DATA_WIDTH + X_PX_WIDTH downto 0);
    signal y_scaled: unsigned(DATA_WIDTH + Y_PX_WIDTH downto 0);
    
    signal x_px: unsigned(X_PX_WIDTH - 1 downto 0);
    signal y_px: unsigned(Y_PX_WIDTH - 1 downto 0);
    
    signal px_addr: std_logic_vector(vram_addr'range);
begin
    x_s <= resize(signed(x), x_s'length);
    y_s <= resize(signed(y), y_s'length);

    -- Shift from [-1, 1) to [0, 2)
    x_shifted <= resize(unsigned(ONE + x_s), x_shifted'length);
    y_shifted <= resize(unsigned(ONE - y_s), y_shifted'length);

    -- Scale to [0, WIDTH_PX) [0, HEIGHT_PX)
    x_scaled <= x_shifted * to_unsigned(WIDTH_PX  / 2, X_PX_WIDTH);
    y_scaled <= y_shifted * to_unsigned(HEIGHT_PX / 2, Y_PX_WIDTH) - 1;

    -- Truncate fractional part
    x_px <= x_scaled(DATA_WIDTH + X_PX_WIDTH - 2 downto DATA_WIDTH - 1);
    y_px <= y_scaled(DATA_WIDTH + Y_PX_WIDTH - 2 downto DATA_WIDTH - 1);

    -- Calculate linear address: y_px * WIDTH_PX + x_px    
    px_addr <= std_logic_vector(resize(y_px * to_unsigned(WIDTH_PX, clog2(WIDTH_PX + 1)) + resize(x_px, y_px'length + clog2(WIDTH_PX + 1)), px_addr'length));

    --! VRAM write control
    process(clk, rst)
    begin
        if rst then
           vram_we   <= '0';            
           vram_addr <= (others => '0');
        elsif rising_edge(clk) then
            if we then
                vram_we   <= '1';
                vram_addr <= px_addr;
            else
                vram_we   <= '0';
            end if;
        end if;    
    end process;
    
    vram_din <= '1';
end architecture;
