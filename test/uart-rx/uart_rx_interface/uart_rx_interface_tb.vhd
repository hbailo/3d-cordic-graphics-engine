library ieee;
use ieee.std_logic_1164.all;

entity uart_rx_interface_tb is
end uart_rx_interface_tb;

architecture behavioral of uart_rx_interface_tb is
  constant CLK_FREQ   : positive := 50_000_000;   -- [Hz]
  constant CLK_PERIOD : time := 1 sec / CLK_FREQ;
  
  signal clk       : std_logic := '0';
  signal rst       : std_logic;
  signal rx_done   : std_logic;
  signal rx_data   : std_logic_vector(7 downto 0);
  signal rx_read   : std_logic;
  signal rx_buffer : std_logic_vector(7 downto 0);
  signal rx_empty  : std_logic;
begin
  dut: entity work.uart_rx_interface
      port map (
          clk       => clk,
          rst       => rst,
          rx_done   => rx_done,
          rx_data   => rx_data,
          rx_read   => rx_read,
          rx_buffer => rx_buffer,
          rx_empty  => rx_empty
      );
  
  clk <= not clk after CLK_PERIOD / 2;
  rst <= '1', '0' after 2 * CLK_PERIOD;

  -- Stimulus
  process
  begin
      wait until rst = '0';
      
      assert rx_empty = '1' report "rx_empty not '1' after reset" severity failure;

      wait for CLK_PERIOD;
      
      -- Simulate reception of byte
      rx_data <= b"1110_0101";
      rx_done <= '1';      
      wait for CLK_PERIOD;
      rx_done <= '0';
      wait for CLK_PERIOD;
      
      assert rx_empty  = '0' report "rx_empty not '0' after rx_done" severity error;
      assert rx_buffer = b"1110_0101" report "rx_buffer != 1110_0101 after rx_data = 1110_0101 and rx_done" severity error;

      -- Simulate read operation
      rx_read <= '1';
      wait for CLK_PERIOD;
      rx_read <= '0';
      wait for CLK_PERIOD;

      assert rx_empty = '1' report "rx_empty not '1' after rx_read" severity error;
      assert rx_buffer = b"0000_0000" report "rx_buffer not cleared after rx_read" severity error;
      wait;
  end process;
end behavioral;
