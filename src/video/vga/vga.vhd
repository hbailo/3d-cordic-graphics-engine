--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.math_real.all;
use ieee.std_logic_1164.all;

--! @brief Top-level VGA display module
--! @details
--! Integrates a VGA controller and an image generator to drive a 640×480 @
--! 50 or 60 Hz display. The refresh rate, the bitmap showed position and it's
--! size are configurable via generics.
--!
--! Provides sync signals, RGB outputs, pixel VRAM addressing, and refresh tick generation.
--! 
--! \pre A clk signal of 50 MHz is assumed.
entity vga is
    generic (
        --! Display refresh rate in Hz        
        REFRESH_RATE: positive;
        
        --! Bitmap width in pixels        
        BITMAP_WIDTH_PX: positive range 1 to 640;

        --! Bitmap height in pixels        
        BITMAP_HEIGHT_PX: positive range 1 to 480;

        --! Horizontal start coordinate of the image window
        BITMAP_X_START_PX: natural range 0 to 640 - BITMAP_WIDTH_PX;

        --! Vertical start coordinate of the image window
        BITMAP_Y_START_PX: natural range 0 to 480 - BITMAP_HEIGHT_PX;

        --! Number of VRAM address bits
        VRAM_ADDR_WIDTH: positive := integer(ceil(log2(real(BITMAP_WIDTH_PX * BITMAP_HEIGHT_PX))))
    );
    
    port (
        --! System clock
        clk: in std_logic;

        --! Active-high asynchronous reset        
        rst: in std_logic;

        --! Pixel VRAM address output
        vram_addr: out std_logic_vector(VRAM_ADDR_WIDTH - 1 downto 0);

        --! Pixel data input from VRAM        
        vram_dout: in std_logic;

        --! Refresh tick at the end of the bitmap frame        
        refresh_tick: out std_logic;

        --! Horizontal sync output        
        h_sync: out std_logic;

        --! Vertical sync output        
        v_sync: out std_logic;
        
        --! Red channel output (monochrome)
        red: out std_logic;
        
        --! Green channel output (monochrome)
        green: out std_logic;

        --! Blue channel output (monochrome)
        blue: out std_logic
    );
end entity;

--! @brief Structural architecture of the VGA display module
--! @details
--! Instantiates:
--! - `vga_controller`: generates sync signals, pixel clock enable, and next pixel coordinates.
--! - `image_generator`: converts pixel coordinates to VRAM addresses, reads pixel data, and outputs RGB signals.
architecture structural of vga is
    signal pixel_ce: std_logic;
    signal next_pixel_x: std_logic_vector(9 downto 0);
    signal next_pixel_y: std_logic_vector(9 downto 0);
begin
    --! VGA controller
    vga_controller: entity work.vga_controller
        generic map (
            REFRESH_RATE => REFRESH_RATE
        )
        port map (
            clk          => clk,
            rst          => rst,
            h_sync       => h_sync,
            v_sync       => v_sync,
            pixel_ce     => pixel_ce,
            next_pixel_x => next_pixel_x,
            next_pixel_y => next_pixel_y
        );

    --! Image generator
    image_generator: entity work.image_generator
        generic map (
            WIDTH_PX   => BITMAP_WIDTH_PX,
            HEIGHT_PX  => BITMAP_HEIGHT_PX,
            X_START_PX => BITMAP_X_START_PX,
            Y_START_PX => BITMAP_Y_START_PX
        )
        port map (
            clk          => clk,
            rst          => rst,
            pixel_ce     => pixel_ce,
            pixel_x      => next_pixel_x,
            pixel_y      => next_pixel_y,
            vram_dout    => vram_dout,
            vram_addr    => vram_addr,
            refresh_tick => refresh_tick,
            red          => red,
            green        => green,
            blue         => blue
        );
end architecture;
