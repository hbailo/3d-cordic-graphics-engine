--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! @brief UART Receiver Interface
--!
--! Provides a simple interface to store a received UART byte and signal
--! when the buffer is empty. The buffer is updated when @p rx_done is
--! asserted, and cleared when @p rx_read is asserted.
entity uart_rx_interface is
    port (
        --! System clock
        clk: in  std_logic;

        --! @brief Async reset
        --! @details Active high
        rst: in  std_logic;

        --! @brief Reception done signal
        rx_done: in  std_logic;

        --! Received data byte
        rx_data: in  std_logic_vector(7 downto 0);

        --! @brief Read signal
        --! @details Consumes the byte in the buffer
        rx_read: in  std_logic;

        --! Output buffer containing the last received byte
        rx_buffer: out std_logic_vector(7 downto 0);

        --! @brief Buffer empty flag
        --! @details '1' when buffer is empty, '0' otherwise
        rx_empty  : out std_logic
    );
end uart_rx_interface;

--! @brief Behavioral architecture of UART RX interface.
--! @details Implements the UART RX buffer logic using a single process.
architecture behavioral of uart_rx_interface is
begin
    process(clk, rst)
    begin
        if rst then
            rx_empty  <= '1';
            rx_buffer <= (others => '0');
        elsif rising_edge(clk) then
            if rx_done then
                rx_empty  <= '0';
                rx_buffer <= rx_data;
            elsif rx_read then
                rx_empty  <= '1';
                rx_buffer <= (others => '0');
            end if;
        end if;
    end process;
end behavioral;
