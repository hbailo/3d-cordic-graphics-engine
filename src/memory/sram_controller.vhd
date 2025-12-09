library ieee;
use ieee.std_logic_1164.all;

--! @brief SRAM controller for IS61LV25616AL
--! @details
--! Provides a 32-bit read/write interface over a pair of 16-bit asynchronous
--! SRAM banks (A and B) from the IS61LV25616AL family.
--!
--! The controller sequences the CE#, OE#, and WE# signals required by the
--! SRAM.
--! Upper 16 bits are mapped to bank A, and lower 16 bits to bank B.
--!
--! A new transaction can only be started when `ready` is high.
entity sram_controller is
    port (
        --! System clock        
        clk: in std_logic;

        --! Active-high asynchronous reset        
        rst: in std_logic;
        
        --! Start a read or write transaction
        start: in std_logic;

        --! Read/Write selector: '1' = read, '0' = write        
        rw: in std_logic;
        
        --! 18-bit SRAM address (shared by both banks)
        addr: in std_logic_vector(17 downto 0);

        --! 32-bit data input for write operations        
        din: in std_logic_vector(31 downto 0);
        
        --! 32-bit data output for read operations        
        dout: out std_logic_vector(31 downto 0);
        
        --! @brief Ready flag
        --! @details High when controller is idle and ready for a new transaction
        ready: out std_logic;

        --! Address bus for SRAM bank A        
        addr_a: out std_logic_vector(17 downto 0);

        --! 16-bit bidirectional data bus for bank A        
        dio_a: inout std_logic_vector(15 downto 0);

        --! Write enable for bank A (active low)        
        we_n_a: out std_logic;
        
        --! Output enable for bank A (active low)        
        oe_n_a: out std_logic;

        --! Chip enable for bank A (active low)        
        ce_n_a: out std_logic;

        --! Upper byte enable for bank A (active low)        
        ub_n_a: out std_logic;
        
        --! Lower byte enable for bank A (active low)        
        lb_n_a: out std_logic;

        --! Address bus for SRAM bank B        
        addr_b: out std_logic_vector(17 downto 0);

        --! 16-bit bidirectional data bus for bank B        
        dio_b: inout std_logic_vector(15 downto 0);

        --! Write enable for bank B (active low)        
        we_n_b: out std_logic;

        --! Output enable for bank B (active low)        
        oe_n_b: out std_logic;

        --! Chip enable for bank B (active low)        
        ce_n_b: out std_logic;

        --! Upper byte enable for bank B (active low)        
        ub_n_b: out std_logic;

        --! Lower byte enable for bank B (active low)        
        lb_n_b: out std_logic
    );
end;

--! @brief FSM architecture of the SRAM controller
--! @details
--! Implements a five-state FSM (IDLE, READING_1, READING_2,
--! WRITING_1, WRITING_2) that sequences all SRAM control
--! strobes according to the IS61LV25616AL timing model.
--!
--! Performs 2-cycle read and write operations:
--! - Read:   READING_1 (address setup) => READING_2 (data capture)
--! - Write:  WRITING_1 (address + data + WE# asserted) => WRITING_2 (WE# release)
architecture fsm of sram_controller is
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
            dio_a  <= (others => 'Z');
            we_n_a <= '1';
            oe_n_a <= '1';
            ce_n_a <= '0';
            ub_n_a <= '0';
            lb_n_a <= '0';
                
            addr_b <= (others => '0');
            dio_b  <= (others => 'Z');
            we_n_b <= '1';
            oe_n_b <= '1';                
            ce_n_b <= '0';                
            ub_n_b <= '0';
            lb_n_b <= '0';

            ready <= '1';
        elsif rising_edge(clk) then
            case next_state is
            when IDLE =>
                addr_a <= (others => '0');
                dio_a  <= (others => 'Z');
                we_n_a <= '1';
                oe_n_a <= '1';
                ce_n_a <= '0';
                ub_n_a <= '0';
                lb_n_a <= '0';
                
                addr_b <= (others => '0');
                dio_b  <= (others => 'Z');
                we_n_b <= '1';
                oe_n_b <= '1';                
                ce_n_b <= '0';                
                ub_n_b <= '0';
                lb_n_b <= '0';
                
                ready <= '1';
               
            when READING_1 =>
                addr_a <= addr;
                dio_a  <= (others => 'Z');
                we_n_a <= '1';
                oe_n_a <= '0';
                ce_n_a <= '0';
                ub_n_a <= '0';
                lb_n_a <= '0';
                
                addr_b <= addr;
                dio_b  <= (others => 'Z');
                we_n_b <= '1';
                oe_n_b <= '0';                
                ce_n_b <= '0';                
                ub_n_b <= '0';
                lb_n_b <= '0';

                ready <= '0';
                
            when READING_2 =>
                null;
                        
            when WRITING_1 =>
                addr_a <= addr;
                dio_a  <= din(31 downto 16);
                we_n_a <= '0';
                oe_n_a <= '1';
                ce_n_a <= '0';
                ub_n_a <= '0';
                lb_n_a <= '0';
                
                addr_b <= addr;
                dio_b  <= din(15 downto 0);
                we_n_b <= '0';
                oe_n_b <= '1';                
                ce_n_b <= '0';                
                ub_n_b <= '0';
                lb_n_b <= '0';                

                ready <= '0';
                
            when WRITING_2 =>
                we_n_a <= '1';
                we_n_b <= '1';
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
                dout <= dio_a & dio_b;

            when WRITING_1 =>
                null;
            
            when WRITING_2 =>
                null;
            end case;
        end if;
    end process;
end architecture;
