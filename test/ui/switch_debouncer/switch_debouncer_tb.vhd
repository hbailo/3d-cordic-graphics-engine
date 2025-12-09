library ieee;
use ieee.std_logic_1164.all;

entity switch_debouncer_tb is
end;

architecture behavioral of switch_debouncer_tb is
    constant CLK_FREQ_HZ        : positive := 50_000_000;
    constant DEBOUNCE_PERIOD_MS : positive := 2;  
    constant CLK_PERIOD         : time := 1 sec / CLK_FREQ_HZ;
    
    signal clk   : std_logic := '0';
    signal rst   : std_logic;
    signal sw    : std_logic := '0';
    signal sw_db : std_logic;
begin
    dut: entity work.switch_debouncer
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS
        )
        port map (
            clk   => clk,
            rst   => rst,
            sw    => sw,
            sw_db => sw_db
        );

    clk <= not clk after CLK_PERIOD / 2;
    rst <= '1', '0' after CLK_PERIOD / 4;
    
    process
    begin
        wait until rst = '0';

        --Bouncing press
        sw <= '1'; wait for 200 us;
        sw <= '0'; wait for 300 us;
        sw <= '1'; wait for 500 us;
        sw <= '0'; wait for 1000 us;
        sw <= '1';
        
        wait for 2 * DEBOUNCE_PERIOD_MS * 1 ms ;
        
        -- Bouncing release
        sw <= '0'; wait for 600 us;        
        sw <= '1'; wait for 600 us;
        sw <= '0'; wait for 150 us;
        sw <= '1'; wait for 200 us;
        sw <= '0';
        
        wait;
    end process;
end;
