library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity cordic_postprocessor_tb is
end entity;

architecture behavioral of cordic_postprocessor_tb is  
    constant CLK_FREQ   : positive := 50_000_000;
    constant CLK_PERIOD : time   := 1 sec / CLK_FREQ;
    
    constant DATA_WIDTH : positive := 9;

    -- DUT signals
    signal clk : std_logic := '0';
    signal rst : std_logic;
    signal xi  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal yi  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal zi  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal xo  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal yo  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal zo  : std_logic_vector(DATA_WIDTH - 1 downto 0);      
begin
    dut: entity work.cordic_postprocessor
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk => clk,
            rst => rst,      
            xi  => xi,
            yi  => yi,
            zi  => zi,
            xo  => xo,
            yo  => yo,
            zo  => zo
        );

    clk <= not clk after CLK_PERIOD / 2;
    
    process
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '1';
        
        wait until rising_edge(clk);
        xi <= std_logic_vector(to_signed(99, DATA_WIDTH));
        yi <= std_logic_vector(to_signed(-33, DATA_WIDTH));
        zi <= std_logic_vector(to_signed(1, DATA_WIDTH));
        
        wait;
    end process;                    
end architecture;
