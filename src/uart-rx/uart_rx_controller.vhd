--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! @brief UART receiver controller.
--! @details
--! Finite state machine that receives serial data on @p rx using 16× oversampling
--! from @p baud_x16_ena, reconstructs one data byte, and asserts @p rx_done when
--! reception completes successfully.  
--! It controls the UART baud rate generator via @p baud_rate_gen_ena.
entity uart_rx_controller is
    port (
        --! @brief System clock
        clk: in std_logic;

        --! @brief Async reset
        --! @details Active high
        rst: in std_logic;

        --! @brief 16x baud rate enable input
        baud_x16_ena: in std_logic;

        --! @brief Serial data input line
        rx: in std_logic;

        --! @brief Reception done pulse
        --! @details 1 cycle long
        rx_done: out std_logic;

        --! @brief Received data byte
        rx_data: out std_logic_vector(7 downto 0);

        --! @brief Baud rate generator enable
        baud_rate_gen_ena: out std_logic
    );
end uart_rx_controller;

--! @brief FSM-based UART receiver architecture.
--! @details
--! Performs start-bit detection, 8-bit data sampling, stop-bit validation,
--! and error detection. Data is sampled at the bit midpoint (X16_BIT_MID_MID)
--! for noise immunity.
architecture fsm of uart_rx_controller is
    --! @brief Midpoint sample tick within a 16x oversampled bit
    constant X16_BIT_MID: integer := 7;
    
    --! @brief End sample tick within a 16x oversampled bit
    constant X16_BIT_END: integer := 15;

    --! @brief Index of the last data bit in an 8-bit UART frame.
    constant FINAL_BIT_INDEX: integer := 7;

    --! @brief FSM states
    type state_t is (IDLE, START_BIT, DATA_BYTE, STOP_BIT, DONE, FAIL);

    signal state: state_t;  --! Current state
    signal next_state: state_t;  --! Next state
    signal baud_x16_ena_count: unsigned(3 downto 0);  --! Count of x16 ena pulses
    signal data_bit_index: unsigned(2 downto 0);  --! Current data bit index
    signal rx_buf: std_logic_vector(rx_data'range);  --! Shift register buffer
begin
    --! @brief State register
    process(clk, rst)
    begin
        if rst then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    --! @brief Next state logic
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

    rx_data <= rx_buf when state = DONE else
            (others => '0');

    baud_rate_gen_ena <= '0' when state = IDLE or state = FAIL else
                         '1';

    --! @brief Baud x16 ena tick counter
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

    --! @brief Data buffer shift register
    process(clk, rst)
    begin
        if rst then
            rx_buf         <= (others => '0');
            data_bit_index <= (others => '0');            
        elsif rising_edge(clk) then
            if state = DATA_BYTE and baud_x16_ena = '1' then
                if baud_x16_ena_count = X16_BIT_MID then
                    rx_buf <= rx & rx_buf(7 downto 1);
                elsif baud_x16_ena_count = X16_BIT_END then
                    data_bit_index <= data_bit_index + 1;
                end if;
            end if;
        end if;
    end process;
end fsm;
