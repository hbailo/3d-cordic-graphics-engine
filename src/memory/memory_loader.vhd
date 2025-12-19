--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! @brief Byte buffer to RAM memory loader
--! @details
--! Receives 8-bit buffered bytes, assembles them into 32-bit words, and writes them
--! sequentially into RAM.
--! When all `DATA_POINTS` are written, `loaded` is asserted.
entity memory_loader is
    generic (
        --! Total number of 32-bit points to load        
        DATA_POINTS: positive;

        --! RAM address width
        ADDR_WIDTH: positive := integer(ceil(log2(real(DATA_POINTS))))
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

        --! RAM is ready to accept a write command
        ram_ready: in std_logic;
        
        --! RAM write address
        ram_addr: out std_logic_vector(ADDR_WIDTH - 1 downto 0);
        
        --! Data to be written to RAM             
        ram_din: out std_logic_vector(31 downto 0);

        --! Start a RAM write
        ram_start: out std_logic;
        
        --! RAM read / write selector (always write='0')               
        ram_rw: out std_logic;

        --! Memory loaded flag
        loaded: out std_logic
    );
end entity;

--! @brief FSM architecture of the memory loader
--! @details
--! Uses a simple FSM to manage byte packing, RAM write handshaking, and
--! address progression.
--! Implements a five-state FSM:
--! - IDLE                : wait for first byte in buffer
--! - BUILDING_DATA_POINT : shift in 4 bytes  
--! - WRITING_DATA_POINT  : initiate RAM write  
--! - NEXT_DATA_POINT     : increment address/counter  
--! - DONE                : loading complete  
architecture fsm of memory_loader is
    constant LAST_DATA_POINT_INDEX: positive := DATA_POINTS - 1;
    
    type state_t is (IDLE, BUILDING_DATA_POINT, WRITING_DATA_POINT, NEXT_DATA_POINT, DONE);
  
    signal state: state_t;
    signal next_state: state_t;
    
    signal data_point: std_logic_vector(ram_din'range);    
    signal data_point_index: unsigned(ram_addr'range);
    
    signal byte_count: unsigned(2 downto 0);
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
            if ram_ready = '1' then
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
            rx_read    <= '0';
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

    --! RAM outputs
    process(all)
    begin
        ram_rw    <= '0';
        ram_din   <= data_point;
        ram_addr  <= std_logic_vector(data_point_index);
        ram_start <= ram_ready when next_state = WRITING_DATA_POINT else
                     '0';        
    end process;    
end architecture;
