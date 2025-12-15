library ieee;
use ieee.std_logic_1164.all;

entity meta_harden_tb is
end meta_harden_tb;

architecture behavioral of meta_harden_tb is
  
  signal clk  : std_logic := '0';
  signal rst  : std_logic := '1';
  signal async: std_logic := '0';
  signal sync : std_logic;
  
begin

  dut: entity work.meta_harden
    port map (
      clk   => clk,
      rst   => rst,
      async => async,
      sync  => sync
    );

  clk   <= not clk after 0.5 us;
  rst   <= '0' after 3 us ;
  async <= '1' after 4.7 us, '0' after 8.3 us, '1' after 11.1 us;
                           
end behavioral;   
