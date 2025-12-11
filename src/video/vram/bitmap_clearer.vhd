--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

--! @brief Bitmap clearing controller
--! @details
--! Iterates through all VRAM addresses of a WIDTH_PX x HEIGHT_PX bitmap.
--! Upon start, the module begins issuing sequential addresses starting
--! from zero and continues until the last pixel address is reached.
--! The ready signal indicates when the module is idle and prepared
--! for a new clearing cycle.
entity bitmap_clearer is
    generic (
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

        --! Asynchronous active high reset        
        rst: in std_logic;
        
        --! @brief Start pulse
        --! @details Begins the bitmap clearing sequence        
        start: in std_logic;

        --! Write enable for VRAM
        vram_we: out std_logic;
        
        --! Pixel VRAM address
        vram_addr: out std_logic_vector(ADDR_WIDTH - 1 downto 0);

        --! Pixel data to be written into VRAM
        vram_din: out std_logic;
        
        --! @brief Ready flag
        --! @details High when IDLE; low during clearing        
        ready: out std_logic
    );
end entity;

--! @brief FSM architecture of the bitmap clearer
--! @details
--! Implements:
--! - A two-state FSM (IDLE, CLEARING)
--! - A pixel address counter running from 0 to BITMAP_LAST_ADDR
--!
--! Operation:
--! - In IDLE: ready = 1 and address register is cleared.
--! - When start is asserted, transitions to CLEARING.
--! - In CLEARING: vram address increments every clock cycle.
--! - When the last address is reached, the FSM returns to IDLE.
architecture fsm of bitmap_clearer is
    constant BITMAP_LAST_ADDR: positive := WIDTH_PX * HEIGHT_PX - 1;
    signal vram_addr_reg: unsigned(vram_addr'range);

    type state_t is (IDLE, CLEARING);
    
    signal state: state_t;
    signal next_state: state_t;
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
            if start then
                next_state <= CLEARING;
            end if;

        when CLEARING =>
            if vram_addr_reg = BITMAP_LAST_ADDR then
                next_state <= IDLE;
            end if;
        end case;
    end process;

    --! Address counter
    process(clk, rst)    
    begin
        if rst then
            vram_addr_reg <= (others => '0');
        elsif rising_edge(clk) then
            case state is
            when IDLE =>
                vram_addr_reg <= (others => '0');                
                
            when CLEARING =>
                vram_addr_reg <= vram_addr_reg + 1;
            end case; 
        end if;
    end process;
    
    --! Ready flag and vram we signal
    process(clk, rst)    
    begin
        if rst then
            vram_we <= '0';
            ready   <= '1';
        elsif rising_edge(clk) then
            case next_state is
            when IDLE =>
                vram_we <= '0';
                ready   <= '1';
                
            when CLEARING =>
                vram_we <= '1';                
                ready   <= '0';
            end case; 
        end if;
    end process;

    vram_addr <= std_logic_vector(vram_addr_reg);
    vram_din  <= '0';    
end;
