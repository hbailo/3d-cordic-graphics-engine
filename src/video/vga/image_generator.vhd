--! @file
--! @author Hernán L. Bailo
--! @date 2025
library ieee;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! @brief VRAM-based bitmap renderer with windowed pixel mapping
--! @details
--! Generates monochrome RGB pixel data from a 1-bit VRAM bitmap.
--! A rectangular window (`WIDTH_PX` x `HEIGHT_PX`) is positioned at
--! (`X_START_PX`, `Y_START_PX`). Pixels inside the window produce
--! RGB = `vram_dout`; pixels outside output black.
--!
--! A single-cycle `refresh_tick` pulse is emitted at the last pixel
--! of the window.
entity image_generator is
    generic (
        --! Bitmap width in pixels        
        WIDTH_PX: positive;
        
        --! Bitmap height in pixels        
        HEIGHT_PX: positive;

        --! Horizontal start coordinate of the image window        
        X_START_PX: natural;

        --! Vertical start coordinate of the image window        
        Y_START_PX: natural;

        --! Number of VRAM address bits        
        VRAM_ADDR_WIDTH: positive := integer(ceil(log2(real(WIDTH_PX * HEIGHT_PX))))        
    );
    
    port (
        --! System clock
        clk: in std_logic;

        --! Active high asynchronous reset
        rst: in std_logic;

        --! Pixel clock enable
        pixel_ce: in std_logic;
        
        --! Current horizontal pixel coordinate        
        pixel_x: in std_logic_vector(9 downto 0);

        --! Current vertical pixel coordinate        
        pixel_y: in std_logic_vector(9 downto 0);

        --! VRAM pixel address        
        vram_addr: out std_logic_vector(VRAM_ADDR_WIDTH - 1 downto 0);

        --! Pixel data from VRAM        
        vram_dout: in std_logic; 

        --! End-of-frame strobe for the bitmap window
        refresh_tick: out std_logic;

        --! Red channel output (monochrome)
        red: out std_logic;

        --! Green channel output (monochrome)
        green: out std_logic;
        
        --! Blue channel output (monochrome)
        blue: out std_logic
    );
end entity;

--! @brief Behavioral architecture of the image generator
--! @details
--! Implements:
--! - Pixel window detection  
--! - Bitmap VRAM address computation  
--! - Monochrome RGB output generation  
--! - End-of-window refresh signaling  
architecture behavioral of image_generator is
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
    
    signal pixel_x_u: unsigned(pixel_x'range);
    signal pixel_y_u: unsigned(pixel_y'range);
    
    signal bitmap_on: std_logic;
begin
    pixel_x_u <= unsigned(pixel_x);
    pixel_y_u <= unsigned(pixel_y);

    -- Pixel on frame flag
    bitmap_on <= '1' when (X_START_PX <= pixel_x_u) and (pixel_x_u < X_START_PX + WIDTH_PX) and (Y_START_PX <= pixel_y_u) and (pixel_y_u < Y_START_PX + HEIGHT_PX) else
                 '0';
    
    -- VRAM linear address computation
    vram_addr <= std_logic_vector(resize((pixel_y_u - Y_START_PX) * to_unsigned(WIDTH_PX, clog2(WIDTH_PX + 1)) + resize(pixel_x_u - X_START_PX, clog2(WIDTH_PX + 1)), vram_addr'length));

    -- Output register
    process (clk, rst)
    begin
        if rst then
            red   <= '0';
            green <= '0';
            blue  <= '0';
            refresh_tick <= '0';
        elsif rising_edge(clk) then
            if pixel_ce = '1' then        
                red   <= vram_dout when bitmap_on else
                         '0';
                green <= vram_dout when bitmap_on else
                         '0';  
                blue  <= vram_dout when bitmap_on else
                         '0';
                
                refresh_tick <= '1' when pixel_x_u = (X_START_PX + WIDTH_PX) and pixel_y_u = (Y_START_PX + HEIGHT_PX - 1) else
                    '0';                
            end if;
        end if;
    end process;
end architecture;
