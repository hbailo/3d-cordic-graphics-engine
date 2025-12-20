library ieee;
use ieee.std_logic_1164.all;

--! @brief BRAM controller
--! @details
--! Provides a 32-bit read/write interface over a synchronous BRAM.
--! A new transaction can only be started when `ready` is high.
entity bram_controller is
    generic (
        ADDR_WIDTH: positive
    );
    port (
        --! System clock        
        clk: in std_logic;

        --! Active-high asynchronous reset        
        rst: in std_logic;
        
        --! Start a read or write transaction
        start: in std_logic;

        --! Read/write selector: '1' = read, '0' = write        
        rw: in std_logic;
        
        --! BRAM address
        addr: in std_logic_vector(ADDR_WIDTH - 1 downto 0);

        --! 32-bit data input for write operations        
        din: in std_logic_vector(31 downto 0);
        
        --! 32-bit data output for read operations        
        dout: out std_logic_vector(31 downto 0);
        
        --! @brief Ready flag
        --! @details High when controller is idle and ready for a new transaction
        ready: out std_logic;

        --! Enable for ram
        bram_ena: out std_logic;
        
        --! Write enable for ram
        bram_we: out std_logic;

        --! Address for ram
        bram_addr: out std_logic_vector(ADDR_WIDTH - 1 downto 0);

        --! Data input for ram
        bram_din: out std_logic_vector(31 downto 0);

        --! Data output for ram
        bram_dout: in std_logic_vector(31 downto 0)
    );
end;

--! @brief FSM architecture of the RAM controller
--! @details
--! Implements a five-state FSM (IDLE, READ_REQUEST, READING_WAIT,
--! WRITE_REQUEST, WRITE_WAIT) that sequences all RAM control
--! strobes.
architecture fsm of bram_controller is
    type state_t is (IDLE, WRITE_REQUEST, WRITE_WAIT, READ_REQUEST, READ_WAIT);
    
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
                if rw = '0' then
                    next_state <= WRITE_REQUEST;
                else
                    next_state <= READ_REQUEST;
                end if;
            end if;
            
        when READ_REQUEST =>
            next_state <= READ_WAIT;

        when READ_WAIT =>
            next_state <= IDLE;

        when WRITE_REQUEST =>
            next_state <= WRITE_WAIT;
            
        when WRITE_WAIT =>
            next_state <= IDLE;
        end case;
    end process;

    --! Mealy outputs (no latency)
    process(clk, rst)
    begin
        if rst then
            bram_we  <= '0';
            bram_ena <= '0';
            ready    <= '1';            
        elsif rising_edge(clk) then
            case next_state is
            when IDLE =>
                bram_we   <= '0';
                bram_ena  <= '0';
                ready     <= '1';
               
            when READ_REQUEST =>
                bram_addr <= addr;            
                bram_ena  <= '1';
                ready     <= '0';
                
            when READ_WAIT =>
                bram_ena  <= '0';                
                        
            when WRITE_REQUEST =>
                bram_addr <= addr;
                bram_we   <= '1';
                bram_ena  <= '1';
                bram_din  <= din;
                ready     <= '0';
                
            when WRITE_WAIT =>
                bram_we   <= '0';
                bram_ena  <= '0';                
            end case;
        end if;
    end process;
    
    dout <= bram_dout;
end architecture;
