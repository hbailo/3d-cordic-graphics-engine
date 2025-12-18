--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

--! @brief Cyclick RAM reader
--! @details
--! Reads 32-bit data points from RAM and extracts three DATA_WIDTH-wide
--! coordinates (x, y, z).
--! The module continuously loops through all the DATA_POINTS in loaded in RAM.
--! The valid flag is asserted when a new coordinate triplet is available.
entity memory_reader is
    generic (
        --! Total number of 32-bit points to read
        DATA_POINTS: positive;
        
        --! Coordinates bit width        
        DATA_WIDTH: positive range 1 to 10;
        
        --! RAM address width
        ADDR_WIDTH: positive := integer(ceil(log2(real(DATA_POINTS))))
    );
    port (
        --! System clock        
        clk: in std_logic;

        --! Active-high asynchronous reset
        rst: in std_logic;

        --! Start reading loop        
        start: in std_logic;
        
        --! RAM is ready to accept a read command        
        ram_ready: in std_logic;

        --! Data readed from RAM                     
        ram_dout: in std_logic_vector(31 downto 0);
        
        --! RAM read address        
        ram_addr: out std_logic_vector(ADDR_WIDTH - 1 downto 0);

        --! Start RAM read strobe
        ram_start: out std_logic;

        --! RAM read / write selector (always read='1')
        ram_rw: out std_logic;

        --! Extracted x coordinate        
        x: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Extracted y coordinate                
        y: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Extracted z coordinate                
        z: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Valid flag asserted when (x,y,z) output is valid
        valid: out std_logic
    );
end entity;

--! @brief FSM architecture of the memory reader.
--! @details
--! Controls address sequencing and read strobes, and extracts packed
--! coordinates from each 32-bit RAM word.
--! A simple FSM manages read cycling:
--! - IDLE               : wait for `start` signal
--! - RESTARTING_READING : reset index  
--! - READING            : issue read strobes and advance address  
architecture fsm of memory_reader is
    constant LAST_DATA_POINT_INDEX: positive := DATA_POINTS - 1;
    
    type state_t is (IDLE, RESTARTING_READING, READING);
    
    signal state: state_t;
    signal next_state: state_t;
    
    signal data_point_index: unsigned(ram_addr'range);
    signal ram_dout_unused: std_logic_vector(31 - 3 * DATA_WIDTH downto 0);
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
                next_state <= RESTARTING_READING;
            end if;

        when RESTARTING_READING =>
            next_state <= READING;
            
        when READING =>
            if data_point_index = LAST_DATA_POINT_INDEX and ram_ready = '1' then
                next_state <= RESTARTING_READING;
            end if;
        end case;
    end process;
    
    --! Point reader
    process(clk, rst)
    begin
        if rst then
            data_point_index <= (others => '0');
        elsif rising_edge(clk) then
            if next_state = RESTARTING_READING then
                data_point_index <= (others => '0');
            elsif state = READING or state = RESTARTING_READING then
                if ram_start = '1' then
                    data_point_index <= data_point_index + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Outputs
    ram_rw    <= '1';
    ram_addr  <= std_logic_vector(data_point_index);
    ram_start <= ram_ready when state = READING or state = RESTARTING_READING else
                  '0';

    x <= ram_dout(31 downto 31 - DATA_WIDTH + 1);
    y <= ram_dout(31 - DATA_WIDTH downto 31 - 2 * DATA_WIDTH + 1);
    z <= ram_dout(31 - 2 * DATA_WIDTH downto 31 - 3 * DATA_WIDTH + 1);
                       
    valid <= ram_ready when state = READING else
             '0';
    
    ram_dout_unused <= ram_dout(31 - 3 * DATA_WIDTH downto 0);
end architecture;
