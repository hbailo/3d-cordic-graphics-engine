library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity vga_controller_tb is
end entity;

architecture behavioral of vga_controller_tb is
    constant CLK_FREQ   : positive := 50_000_000;
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);

    constant REFRESH_RATE : positive := 50; 
    
    -- DUT port
    signal clk          : std_logic := '0';
    signal rst          : std_logic;
    signal h_sync       : std_logic;
    signal v_sync       : std_logic;
    signal next_pixel_x : std_logic_vector(9 downto 0);
    signal next_pixel_y : std_logic_vector(9 downto 0);
    signal pixel_ce     : std_logic;    
begin
    dut: entity work.vga_controller
        generic map (
            REFRESH_RATE => REFRESH_RATE
        )
        port map (
            clk           => clk,
            rst           => rst,
            h_sync        => h_sync,
            v_sync        => v_sync,
            pixel_ce      => pixel_ce,            
            next_pixel_x  => next_pixel_x,
            next_pixel_y  => next_pixel_y
        );
    
    clk <= not clk after CLK_PERIOD / 2;
    rst <= '1', '0' after 2 * CLK_PERIOD;
end architecture;
