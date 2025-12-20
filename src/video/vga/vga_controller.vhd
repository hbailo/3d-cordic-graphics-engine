--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! @brief VGA controller for a 640×480 @ 50 or 60 Hz display
--! @details
--! Generates horizontal and vertical sync signals, pixel clock enable, and pixel coordinates.
--! Assumes a 50 MHz system clock input for 60 Hz operation or 42 MHz clock
--! for 50 Hz.
--! 
--! ## Pixel Coordinate Behavior
--! Coordinates increment within visible areas and wrap properly at the end of each line and frame.
--! During blanking intervals, the module outputs:
--! - `next_pixel_x = 0` outside horizontal display region
--! - `next_pixel_y = 0` when a frame ends
--! - `next_pixel_x` and `next_pixel_y` are sent **ahead of time** to allow fetching the corresponding pixel from external memory with a **one-clock-cycle delay**.
entity vga_controller is
    port (
        --! System clock
        clk: in std_logic;

        --! Active high asynchronous reset
        rst: in std_logic;

        --! Horizontal sync output
        h_sync: out std_logic;

        --! Vertical sync output
        v_sync: out std_logic;

        --! Pixel clock enable
        pixel_ce: out std_logic;
        
        --! Next horizontal pixel coordinate
        next_pixel_x: out std_logic_vector(9 downto 0);

        --! Next vertical pixel coordinate        
        next_pixel_y: out std_logic_vector(9 downto 0)
    );
end entity;

--! @brief Behavioral architecture of the VGA controller
--! @details
--! Implements:
--! - Pixel clock enable generation at half clk frequency.
--! - Horizontal timing generator and sync logic
--! - Vertical timing generator and sync logic
--! - Pixel coordinate output mapping
--!
--! Internal timing follows:
--! - Horizontal timing: display, front porch, sync pulse, back porch  
--! - Vertical timing: display, front porch, sync pulse, back porch  
architecture behavioral of vga_controller is
    -- Horizontal timing parameters
    constant HD: integer := 640;    --! Horizontal display
    constant HF: integer := 16;     --! Horizontal front porch
    constant HB: integer := 48;     --! Horizontal back porch horizontal
    constant HR: integer := 96;     --! Horizontal retrace
    
    constant VD: integer := 480; --! Vertical display
    constant VF: integer := 10;  --! Vertical front porch
    constant VB: integer := 33;  --! Vertival back port
    constant VR: integer := 2;   --! Vertical retrace

    -- Internal counters and flags    
    signal v_count: unsigned(9 downto 0);
    signal h_count: unsigned(9 downto 0);
begin
    --! @brief Pixel clock enable generator
    --! @details
    --! Divides the 50 MHz clock by 2 to produce a 25 MHz pixel enable tick.
    process(clk, rst)
    begin
        if rst then
            pixel_ce <= '0';
        elsif rising_edge(clk) then
            pixel_ce <= not pixel_ce;
        end if;
    end process;

    --! Horizontal timing generator
    process(clk, rst)
    begin
        if rst then
            h_sync  <= '1';
            h_count <= to_unsigned((HD + HF + HR + HB - 1), h_count'length);
        elsif rising_edge(clk) then
            if pixel_ce then
                if h_count < HD - 1 then
                    h_sync  <= '1';
                    h_count <= h_count + 1;
                elsif h_count < HD + HF - 1 then
                    h_sync  <= '1';
                    h_count <= h_count + 1;
                elsif h_count < HD + HF + HR - 1 then
                    h_sync  <= '0';
                    h_count <= h_count + 1;
                elsif h_count < HD + HF + HR + HB - 1 then
                    h_sync  <= '1';
                    h_count <= h_count + 1;
                else
                    h_sync  <= '1';
                    h_count <= (others => '0');
                end if;
            end if;
        end if;
    end process;
   
    --! Vertical timing generator
    process(clk, rst)
    begin
        if rst then
            v_sync  <= '1';
            v_count <= to_unsigned((VD + VF + VR + VB - 1), v_count'length);
        elsif rising_edge(clk) then
            if pixel_ce = '1' and h_count = HD + HF + HR + HB - 1 then
                if v_count < VD - 1 then
                    v_sync  <= '1';
                    v_count <= v_count + 1;
                elsif v_count < VD + VF - 1 then
                    v_sync  <= '1';
                    v_count <= v_count + 1;
                elsif v_count < VD + VF + VR - 1 then
                    v_sync  <= '0';
                    v_count <= v_count + 1;
                elsif v_count < VD + VF + VR + VB - 1 then
                    v_sync  <= '1';
                    v_count <= v_count + 1;
                else
                    v_sync  <= '1';
                    v_count <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    -- Next pixel coordinate output mapping    
    next_pixel_x <= std_logic_vector(h_count + 1) when h_count < HD + HF + HR + HB - 1 else
               (others => '0');
    
    next_pixel_y <= std_logic_vector(v_count + 1) when h_count = HD + HF + HR + HB - 1 and v_count < VD + VF + VR + VB - 1 else
               (others => '0')               when h_count = HD + HF + HR + HB - 1 and v_count = VD + VF + VR + VB - 1 else
               std_logic_vector(v_count);
end architecture;
