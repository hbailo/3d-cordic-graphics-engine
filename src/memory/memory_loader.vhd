--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief Byte buffer to SRAM memory loader.
--! @details
--! Receives 8-bit buffered bytes, assembles them into 32-bit words, and writes them
--! sequentially into SRAM.  
--! When all `DATA_POINTS` words are written, `loaded` is asserted.
entity memory_loader is
    generic (
        --! Total number of 32-bit points to load        
        DATA_POINTS: positive range 1 to 2**18
    );
    port (
        --! System clock
        clk: in std_logic;

        --! Active-high asynchronous reset
        rst: in std_logic;

        --! Received byte buffer
        rx_buffer: in std_logic_vector(7 downto 0);

        --! Rx buffer is empty        
        rx_empty: in std_logic;

        --! Rx buffer read strobe (one cycle)        
        rx_read: out std_logic;

        --! SRAM is ready to accept a write command
        sram_ready: in std_logic;
        
        --! SRAM write address
        sram_addr: out std_logic_vector(17 downto 0);
        
        --! Data to be written to SRAM             
        sram_din: out std_logic_vector(31 downto 0);

        --! Start a SRAM write
        sram_start: out std_logic;
        
        --! SRAM read / write selector (always write='0')               
        sram_rw: out std_logic;

        --! Memory loaded flag
        loaded: out std_logic
    );
end entity;

--! @brief FSM architecture of the memory loader
--! @details
--! Uses a simple FSM to manage byte packing, SRAM write handshaking, and
--! address progression.
--! Implements a five-state FSM:
--! - **IDLE**: wait for first byte in buffer
--! - **BUILDING_DATA_POINT**: shift in 4 bytes  
--! - **WRITING_DATA_POINT**: initiate SRAM write  
--! - **NEXT_DATA_POINT**: increment address/counter  
--! - **DONE**: loading complete  
architecture fsm of memory_loader is
    constant LAST_DATA_POINT_INDEX: positive := DATA_POINTS - 1;
    
    type state_t is (IDLE, BUILDING_DATA_POINT, WRITING_DATA_POINT, NEXT_DATA_POINT, DONE);
  
    signal state: state_t;
    signal next_state: state_t;

    signal byte_count: unsigned(2 downto 0);
    
    signal data_point: std_logic_vector(31 downto 0);    
    signal data_point_index: unsigned(17 downto 0);
begin
    --! State register    
    process (clk, rst)
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
            if not rx_empty then
                next_state <= BUILDING_DATA_POINT;
            end if;
            
        when BUILDING_DATA_POINT =>
            if byte_count = 4 then
                next_state <= WRITING_DATA_POINT;
            end if;
            
        when WRITING_DATA_POINT =>
            if sram_ready = '1' then
                next_state <= NEXT_DATA_POINT;
            end if;

        when NEXT_DATA_POINT =>
            if data_point_index = LAST_DATA_POINT_INDEX then
                next_state <= DONE;
            else
                next_state <= IDLE;
            end if;               
            
        when DONE =>
            null;
        end case;
    end process;

    --! Data point builder
    process(clk, rst)
    begin
        if rst then
            data_point <= (others => '0');
            byte_count <= (others => '0');
            rx_read  <= '0';
        elsif rising_edge(clk) then
            if state = BUILDING_DATA_POINT then
                if rx_empty = '0' and rx_read = '0' then
                    data_point <= data_point(23 downto 0) & rx_buffer;
                    byte_count <= byte_count + 1;
                    rx_read  <= '1';
                else
                    rx_read <= '0';
                end if;
            else
                byte_count <= (others => '0');
            end if;
        end if;
    end process;

    --! Data point writer
    process(all)
    begin
        sram_rw    <= '0';
        sram_din   <= data_point;
        sram_addr  <= std_logic_vector(data_point_index);
        sram_start <= sram_ready when next_state = WRITING_DATA_POINT else
                      '0';        
    end process;

    --! Next data point advancer
    process(clk, rst)
    begin
        if rst then
            data_point_index <= (others => '0');
        elsif rising_edge(clk) then
            if state = NEXT_DATA_POINT then
                data_point_index <= data_point_index + 1;
            end if;
        end if;
    end process;

    --! Write done signaler
    process(clk, rst)
    begin
        if rst then
            loaded <= '0';
        elsif rising_edge(clk) then
            if next_state = DONE then
                loaded <= '1';
            end if;
        end if;
    end process;    
end architecture;
