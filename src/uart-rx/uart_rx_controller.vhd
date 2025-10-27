library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity uart_rx_controller is
    port (
        clk               : in  std_logic;
        rst               : in  std_logic;
        baud_x16_ena      : in  std_logic;
        rx                : in  std_logic;
        rx_done           : out std_logic;
        data              : out std_logic_vector(7 downto 0);
        baud_rate_gen_ena : out std_logic
        );
end uart_rx_controller;

architecture fsm of uart_rx_controller is
    constant X16_BIT_MID: integer := 7;
    constant X16_BIT_END: integer := 15;
    constant FINAL_BIT_INDEX: integer := 7;
    
    type state_t is (IDLE, START_BIT, DATA_BYTE, STOP_BIT, DONE, FAIL);

    signal state: state_t;
    signal next_state: state_t;
    signal baud_x16_ena_count: unsigned(3 downto 0);
    signal data_bit_index: unsigned(2 downto 0);
    signal data_buf: std_logic_vector(data'range);
begin
    -- State register
    process(clk, rst)
    begin
        if rst then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    -- Next state logic
    process(all)
    begin
        next_state <= state;
        
        case state is
        when IDLE =>
            if rx = '0' then
                next_state <= START_BIT;
            end if;

        when START_BIT =>
            if baud_x16_ena = '1' then
                if baud_x16_ena_count = X16_BIT_MID and rx = '1' then
                    next_state <= FAIL;
                elsif baud_x16_ena_count = X16_BIT_END then
                    next_state <= DATA_BYTE;
                end if;
            end if;

        when DATA_BYTE =>
            if baud_x16_ena = '1' and baud_x16_ena_count = X16_BIT_END and data_bit_index = FINAL_BIT_INDEX then
                next_state <= STOP_BIT;
            end if;

        when STOP_BIT =>
            if baud_x16_ena = '1' then
                if baud_x16_ena_count = X16_BIT_MID and rx = '0' then
                    next_state <= FAIL;
                elsif baud_x16_ena_count = X16_BIT_END then
                    next_state <= DONE;
                end if; 
            end if;
            
        when DONE =>
            next_state <= IDLE;

        when FAIL =>
            null;
        end case;
    end process;

    -- Outputs
    rx_done <= '1' when state = DONE else
               '0';

    data <= data_buf when state = DONE else
            (others => '0');

    baud_rate_gen_ena <= '0' when state = IDLE or state = FAIL else
                         '1';

    -- Baud x16 ena tick counter
    process(clk, rst)
    begin
        if rst then
            baud_x16_ena_count <= (others => '0');
        elsif rising_edge(clk) then
            if baud_x16_ena then
                if state = IDLE then
                    baud_x16_ena_count <= (others => '0');
                else
                    baud_x16_ena_count <= baud_x16_ena_count + 1;
                end if;
            end if;
        end if;
    end process;

    -- Data bit index tracker
    process(clk, rst)
    begin
        if rst then
            data_bit_index <= (others => '0');
        elsif rising_edge(clk) then
            if state = DATA_BYTE and baud_x16_ena = '1' and baud_x16_ena_count = 15 then
                data_bit_index <= data_bit_index + 1;
            end if;
        end if;
    end process;

    -- Data buffer shift register
    process(clk, rst)
    begin
        if rst then
            data_buf       <= (others => '0');            
            data_bit_index <= (others => '0');
        elsif rising_edge(clk) then
            if state = DATA_BYTE and baud_x16_ena = '1' then
                if baud_x16_ena_count = X16_BIT_MID then
                    data_buf <= rx & data_buf(7 downto 1);
                elsif baud_x16_ena_count = X16_BIT_END then
                    data_bit_index <= data_bit_index + 1;
                end if;
            end if;
        end if;
    end process;
end fsm;
