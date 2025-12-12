--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.std_logic_1164.all;

--! @brief UART receiver module
--! @details
--! Provides input/output ports for UART reception, buffering, and read signaling.
entity uart_rx is
    generic (
        --! System clock frequency in Hz
        CLK_FREQ: positive;

        --! UART baud rate in bits per second
        BAUD_RATE: positive
    );

    port (
        --! System clock
        clk: in std_logic;

        --! @brief Asynchronous reset
        --! @details Active high
        rst: in std_logic;

        --! UART serial data input line
        rx: in std_logic;

        --! @brief Read signal to consume byte from buffer
        --! @details When asserted, clears the buffered byte and updates the rx_empty flag.        
        rx_read: in std_logic;

        --! Output buffer containing last received byte
        rx_buffer: out std_logic_vector(7 downto 0);

        --! Buffer empty flag
        rx_empty: out std_logic
    );
end uart_rx;

--! @brief Structural architecture of the UART Rx module
--! @details
--! Instantiates and interconnects the following components:
--! - @p baud_rate_generator: generates 16× oversampling enable pulses
--!   for precise bit timing.
--! - @p meta_harden: synchronizes asynchronous Rx input to system clock.
--! - @p uart_rx_controller: finite state machine that reconstructs received bytes
--!   and asserts @p rx_done.
--! - @p uart_rx_interface: buffer that latches received bytes and provides
--!   @p rx_empty signaling.  
architecture structural of uart_rx is
    signal baud_x16_ena: std_logic;      --! 16x baud rate enable pulse
    signal baud_rate_gen_ena: std_logic; --! Baud rate generator enable
    signal rx_sync: std_logic;           --! Clk synchronized Rx input
    signal rx_done: std_logic;           --! Reception done pulse from controller
    signal rx_data: std_logic_vector(rx_buffer'range); --! Data byte from controller
begin
    --! Baud rate generator
    baud_rate_generator: entity work.baud_rate_generator
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk          => clk,
            rst          => rst,
            ena          => baud_rate_gen_ena,
            baud_x16_ena => baud_x16_ena            
        );

    --! Meta-harden synchronizer
    meta_harden: entity work.meta_harden
        port map (
            clk   => clk,
            rst   => rst,
            async => rx,
            sync  => rx_sync
        );

    --! UART RX controller
    controller: entity work.uart_rx_controller
        port map (
            clk          => clk,
            rst          => rst,
            baud_x16_ena => baud_x16_ena,
            rx           => rx_sync,
            rx_done      => rx_done,
            rx_data      => rx_data,
            baud_rate_gen_ena => baud_rate_gen_ena        
        );
    
    --! UART RX interface buffer
    interface: entity work.uart_rx_interface
        port map (
            clk       => clk,
            rst       => rst,
            rx_done   => rx_done,
            rx_data   => rx_data,
            rx_read   => rx_read,
            rx_buffer => rx_buffer,
            rx_empty  => rx_empty        
        );
end structural;
