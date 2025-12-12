--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

--! @brief Bitmap sequencer controller
--! @details
--! Coordinates the clearing and drawing of a WIDTH_PX x HEIGHT_PX bitmap.
--! Integrates the `bitmap_clearer` and `bitmap_drawer` modules.
--! 
--! The module multiplexes VRAM write signals from the two submodules to produce
--! a single coherent write interface for the bitmap memory.
entity bitmap_sequencer is
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
 
        draw: in std_logic;
        
        --! x bitmap coordinate
        x: in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! y bitmap coordinate
        y: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        
        clear: in std_logic;

        --! Write enable for VRAM
        vram_we: out std_logic;

        --! Pixel VRAM address        
        vram_addr: out std_logic_vector(ADDR_WIDTH - 1 downto 0);

        --! Pixel data to be written into VRAM        
        vram_din: out std_logic
    );
end entity;

--! @brief FSM architecture of the bitmap sequencer
--! @details
--! Implements a three-state FSM (IDLE, CLEARING, DRAWING) to:
--! - Wait for a start condition (draw or clear)
--! - Trigger the clearing sequence using `bitmap_clearer`
--! - Trigger the drawing sequence using `bitmap_drawer`
architecture fsm of bitmap_sequencer is
    type state_t is (IDLE, CLEARING, DRAWING);
    
    signal state: state_t;
    signal next_state: state_t;

    -- Signals connected to bitmap_clearer
    signal clear_vram_we: std_logic;
    signal clear_vram_addr: std_logic_vector(vram_addr'range);
    signal clear_vram_din: std_logic;    
    signal clear_ready: std_logic;

    -- Signals connected to bitmap_drawer    
    signal draw_vram_we: std_logic;    
    signal draw_vram_addr: std_logic_vector(vram_addr'range);
    signal draw_vram_din: std_logic;        
begin
    --! State register
    process(clk, rst)
    begin
        if rst then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    --! Next state logic
    process(all)
    begin
        next_state <= state;
        
        case state is
        when IDLE =>
            if clear then
                next_state <= CLEARING;
            elsif draw then
                next_state <= DRAWING;
            end if;

        when CLEARING =>
            if clear_ready then
                if draw then
                    next_state <= DRAWING;
                else
                    next_state <= IDLE;
                end if;
            end if;
            
        when DRAWING =>
            if clear then
                next_state <= CLEARING;
            elsif draw then
                next_state <= DRAWING;
            else
                next_state <= IDLE;
            end if;
        end case;
    end process;

    --! VRAM multiplexing logic
    process(all)
    begin
        case state is
        when IDLE =>
            vram_we   <= '0';
            vram_addr <= (others => '0');
            vram_din  <= '0';
                
        when CLEARING =>
            vram_we   <= clear_vram_we;
            vram_addr <= clear_vram_addr;
            vram_din  <= clear_vram_din;
            
        when DRAWING =>
            vram_we   <= draw_vram_we;                
            vram_addr <= draw_vram_addr;
            vram_din  <= draw_vram_din;                
        end case;
    end process;
    
    bitmap_clearer: entity work.bitmap_clearer
        generic map (
            WIDTH_PX  => WIDTH_PX,
            HEIGHT_PX => HEIGHT_PX
        )
        port map (
            clk       => clk,
            rst       => rst,
            start     => clear,
            vram_we   => clear_vram_we,
            vram_addr => clear_vram_addr,
            vram_din  => clear_vram_din,
            ready     => clear_ready
        );
    
    bitmap_drawer: entity work.bitmap_drawer
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            WIDTH_PX   => WIDTH_PX,
            HEIGHT_PX  => HEIGHT_PX
        )        
        port map (
            clk       => clk,
            rst       => rst,
            we        => draw,
            x         => x,
            y         => y,
            vram_we   => draw_vram_we,
            vram_addr => draw_vram_addr,
            vram_din  => draw_vram_din
        );
end architecture;
