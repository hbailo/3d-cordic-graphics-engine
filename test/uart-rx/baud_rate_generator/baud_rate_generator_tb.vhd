library ieee;
use ieee.std_logic_1164.all;

entity baud_rate_generator_tb is
end baud_rate_generator_tb;

architecture behavioral of baud_rate_generator_tb is

  constant CLK_FREQ : positive := 50_000_000; -- [Hz]
  constant BAUD_RATE: positive := 115_200;    -- [bps]

  constant CLK_PERIOD: time := 1 sec / CLK_FREQ;
  constant BAUD_X16_CLK_PERIOD: time := 1 sec / (16 * BAUD_RATE);
  
  signal clk         : std_logic := '0';
  signal rst         : std_logic := '1';
  signal baud_x16_ena: std_logic;
  signal baud_x16_clk: std_logic := '0';
  
begin

  dut: entity work.baud_rate_generator
    generic map (
      CLK_FREQ  => CLK_FREQ,
      BAUD_RATE => BAUD_RATE
    )
    port map (
      clk          => clk,
      rst          => rst,
      baud_x16_ena => baud_x16_ena
    );

  clk <= not clk after CLK_PERIOD / 2;
  rst <= '0' after 2 * CLK_PERIOD;

  -- Baud x16 clock generation
  process
  begin
    wait until falling_edge(baud_x16_ena);
    
    loop
      baud_x16_clk <= '1';
      wait for BAUD_X16_CLK_PERIOD / 2;
      baud_x16_clk <= '0';
      wait for BAUD_X16_CLK_PERIOD / 2;
    end loop;
    
  end process;
  
end behavioral;
