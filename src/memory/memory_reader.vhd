--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief Sequential SRAM point reader.
--! @details
--! Reads 32-bit data points from SRAM and extracts three `DATA_WIDTH`-wide
--! coordinates (x, y, z).  
--! The module continuously loops through all `DATA_POINTS`.  
--! `valid` is asserted when a new coordinate triplet is available.
entity memory_reader is
    generic (
        --! Total number of 32-bit points to read
        DATA_POINTS: positive range 1 to 2**18;
        
        --! Coordinatesbit width        
        DATA_WIDTH: positive range 1 to 10     
    );
    port (
        --! System clock        
        clk: in std_logic;

        --! Active-high asynchronous reset
        rst: in std_logic;

        --! Start reading loop        
        start: in std_logic;
        
        --! SRAM is ready to accept a read command        
        sram_ready: in std_logic;

        --! Data readed from SRAM                     
        sram_dout: in std_logic_vector(31 downto 0);
        
        --! SRAM read address        
        sram_addr: out std_logic_vector(17 downto 0);

        --! Start SRAM read strobe
        sram_start: out std_logic;

        --! SRAM read / write selector (always read='1')                       
        sram_rw: out std_logic;

        --! Extracted X coordinate        
        x: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Extracted Y coordinate                
        y: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Extracted Z coordinate                
        z: out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Valid flag asserted when (x,y,z) output is valid
        valid: out std_logic
    );
end entity;

--! @brief FSM architecture of the memory reader.
--! @details
--! Controls address sequencing and read strobes, and extracts packed
--! coordinates from each 32-bit SRAM word.
--! A simple FSM manages read cycling:
--! - IDLE: wait for `start`  
--! - RESTARTING_READING: reset index  
--! - READING: issue read strobes and advance address  
architecture fsm of memory_reader is
    constant LAST_DATA_POINT_INDEX: positive := DATA_POINTS - 1;
    
    type state_t is (IDLE, RESTARTING_READING, READING);
    
    signal state: state_t;
    signal next_state: state_t;
    
    signal data_point_index: unsigned(sram_addr'range);
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
            if data_point_index = LAST_DATA_POINT_INDEX and sram_ready = '1' then
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
                if sram_start = '1' then
                    data_point_index <= data_point_index + 1;
                end if;
            end if;
        end if;
    end process;

    sram_rw    <= '1';
    sram_addr  <= std_logic_vector(data_point_index);
    sram_start <= sram_ready when state = READING  or state = RESTARTING_READING else
                  '0';

    x <= sram_dout(31 downto 31 - DATA_WIDTH + 1);
    y <= sram_dout(31 - DATA_WIDTH downto 31 - 2 * DATA_WIDTH + 1);
    z <= sram_dout(31 - 2 * DATA_WIDTH downto 31 - 3 * DATA_WIDTH + 1);
    
    valid <= sram_ready when state = READING else
             '0';
end architecture;
