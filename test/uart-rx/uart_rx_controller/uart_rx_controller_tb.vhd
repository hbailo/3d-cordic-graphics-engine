library ieee;
use ieee.std_logic_1164.all;

entity uart_rx_controller_tb is
end uart_rx_controller_tb;

architecture behavioral of uart_rx_controller_tb is
  constant CLK_FREQ  : positive := 50_000_000; -- [Hz]
  constant BAUD_RATE : positive := 115_200;    -- [bps]

  constant CLK_PERIOD : time := 1 sec / CLK_FREQ;
  constant BIT_PERIOD : time := 1 sec / BAUD_RATE;
  constant BAUD_X16_CLK_PERIOD : time := 1 sec / (16 * BAUD_RATE);  

  procedure uart_send_byte(signal rx: out std_logic; data: std_logic_vector(7 downto 0)) is
  begin
    -- Start bit
    rx <= '0';
    wait for BIT_PERIOD;

    -- Data byte. NOTE: LSB first
    for i in 0 to 7 loop
      rx <= data(i);
      wait for BIT_PERIOD;
    end loop;

    -- Stop bit
    rx <= '1';
    wait for BIT_PERIOD;
  end procedure;

  signal clk               : std_logic := '0';
  signal rst               : std_logic := '1';
  signal rx                : std_logic := '1';
  signal baud_rate_gen_ena : std_logic;
  signal baud_x16_ena      : std_logic;

  signal baud_x16_clk : std_logic := '0';
  signal baud_clk     : std_logic := '0';
  
begin

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

  dut: entity work.uart_rx_controller
    port map (
      clk          => clk,
      rst          => rst,
      baud_x16_ena => baud_x16_ena,
      rx           => rx,
      rx_done      => open,
      data         => open,
      baud_rate_gen_ena => baud_rate_gen_ena
    );
  
  clk <= not clk after CLK_PERIOD / 2;
  rst <= '0' after 2 * CLK_PERIOD;

  -- Stimulus
  process
  begin
    wait until rst = '0';
    wait for 5 * CLK_PERIOD;

    -- send 0x55
    uart_send_byte(rx, b"1110_0101");

    wait for 5 * BIT_PERIOD;

    -- send 0xA3
    uart_send_byte(rx, b"0000_1111");

    wait;
  end process;

  -- Baud clock generation
  process
  begin
    wait until rising_edge(baud_rate_gen_ena);
    
    loop
      baud_clk <= '1';
      wait for BIT_PERIOD / 2;
      baud_clk <= '0';
      wait for BIT_PERIOD / 2;
    end loop;
    
  end process;

  -- Baud x16 clock generation
  process
  begin
    wait until rising_edge(baud_rate_gen_ena);
    
    loop
      baud_x16_clk <= '1';
      wait for BAUD_X16_CLK_PERIOD / 2;
      baud_x16_clk <= '0';
      wait for BAUD_X16_CLK_PERIOD / 2;
    end loop;
    
  end process;  
  
end behavioral;
