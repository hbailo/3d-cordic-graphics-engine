library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity uart_rx_controller is
  port (
    clk: in std_logic;
    rst: in std_logic;
    baud_x16_ena: in std_logic;
    rx: in std_logic;
    rx_done: out std_logic;
    data: out std_logic_vector(7 downto 0);
    baud_rate_gen_ena: out std_logic
    );
end uart_rx_controller;

architecture fsm of uart_rx_controller is
  type state_t is (IDLE, START_BIT, DATA_BYTE, STOP_BIT, DONE, FAIL);

  signal state: state_t;  
  signal baud_x16_ena_count: unsigned(3 downto 0);
  signal data_bit_index: unsigned(2 downto 0);
  
begin
  -- State machine
  process(clk, rst)
  begin
    
    if rst then
      state <= IDLE;
      baud_rate_gen_ena <= '0';    
    elsif rising_edge(clk) then

      case state is
      when IDLE =>
        if rx = '0' then
          state <= START_BIT;
          baud_rate_gen_ena <= '1';            
        end if;
          
      when START_BIT =>
        if baud_x16_ena = '1' and baud_x16_ena_count = 7 and rx = '1' then
          state <= FAIL;
        end if;
        
        if baud_x16_ena = '1' and baud_x16_ena_count = 15 then
          state <= DATA_BYTE;
        end if;
            
      when DATA_BYTE =>
        if baud_x16_ena = '1' and baud_x16_ena_count = 7 then
          data <= rx & data(7 downto 1) ;
        end if;

        if baud_x16_ena = '1' and baud_x16_ena_count = 15 and data_bit_index = 7 then
          state <= STOP_BIT;
        end if;

      when STOP_BIT =>
        if baud_x16_ena = '1' and baud_x16_ena_count = 7 and rx = '0' then
          state <= FAIL;
        end if;

        if baud_x16_ena = '1' and baud_x16_ena_count = 15 then
          state <= DONE;
        end if;

      when DONE =>
        state <= IDLE;
        baud_rate_gen_ena <= '0';
          
      when others =>
        baud_rate_gen_ena <= '0';
        null;
      end case;
    end if;
  end process;

  -- Outputs
  rx_done <= '1' when state = DONE else
             '0';

  -- Baud x16 oversample tick counter
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

end fsm;
