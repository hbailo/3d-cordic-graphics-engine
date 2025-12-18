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

        --! Enable for ram port A
        en_a: out std_logic;

        --! Enable for ramport B
        en_b: out std_logic;
        
        --! Write enable for ram port A        
        we_a: out std_logic;

        --! Address for port A
        addr_a: out std_logic_vector(ADDR_WIDTH - 1 downto 0);

        --! Address for port B
        addr_b: out std_logic_vector(ADDR_WIDTH - 1 downto 0);

        --! Data input for ram port A
        din_a: out std_logic_vector(31 downto 0);

        --! Data output for ram port B
        dout_b: in std_logic_vector(31 downto 0)
    );
end;

--! @brief FSM architecture of the RAM controller
--! @details
--! Implements a five-state FSM (IDLE, READING_1, READING_2,
--! WRITING_1, WRITING_2) that sequences all RAM control
--! strobes.
architecture fsm of bram_controller is
    type state_t is (IDLE, READING_1, READING_2, WRITING_1, WRITING_2);
    
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
                    next_state <= WRITING_1;
                else
                    next_state <= READING_1;
                end if;
            end if;
            
        when READING_1 =>
            next_state <= READING_2;

        when READING_2 =>
            next_state <= IDLE;

        when WRITING_1 =>
            next_state <= WRITING_2;
            
        when WRITING_2 =>
            next_state <= IDLE;
        end case;
    end process;

    --! Mealy outputs (no latency)
    process(clk, rst)
    begin
        if rst then
            addr_a <= (others => '0');
            addr_b <= (others => '0');            
            we_a   <= '0';
            en_a   <= '0';
            en_b   <= '0';
            din_a  <= (others => '0');
            ready  <= '1';
        elsif rising_edge(clk) then
            case next_state is
            when IDLE =>
                addr_a <= (others => '0');
                addr_b <= (others => '0');            
                we_a   <= '0';
                en_a   <= '0';
                en_b   <= '0';
                din_a  <= (others => '0');
                ready  <= '1';
               
            when READING_1 =>
                addr_a <= (others => '0');
                addr_b <= addr;            
                we_a   <= '0';
                en_a   <= '0';
                en_b   <= '1';
                din_a  <= (others => '0');
                ready  <= '0';
                
            when READING_2 =>
                null;
                        
            when WRITING_1 =>
                addr_a <= addr;
                addr_b <= (others => '0');            
                we_a   <= '1';
                en_a   <= '1';
                en_b   <= '0';
                din_a  <= din;
                ready  <= '0';
                
            when WRITING_2 =>
                null;
            end case;
        end if;
    end process;

    --! Moore outputs (1 clk latency)
    process(clk, rst)
    begin
        if rst then
            dout <= (others => '0');
        elsif rising_edge(clk) then
            case state is
            when IDLE =>
                null;
            
            when READING_1 =>
                null;

            when READING_2 =>
                dout <= dout_b;

            when WRITING_1 =>
                null;
            
            when WRITING_2 =>
                null;
            end case;
        end if;
    end process;
end architecture;
