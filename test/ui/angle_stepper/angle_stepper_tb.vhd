library ieee;
use ieee.std_logic_1164.all;

entity angle_stepper_tb is
end;

architecture tb of angle_stepper_tb is
    constant CLK_FREQ_HZ : positive := 5_000;
    constant CLK_PERIOD  : time     := 1 sec / CLK_FREQ_HZ;
    constant ANGLE_WIDTH : positive := 9;
    constant ANGULAR_VEL_DEG_S : positive := 45;    

    signal clk   : std_logic := '0';
    signal rst   : std_logic;
    signal up    : std_logic := '0';
    signal down  : std_logic := '0';
    signal angle : std_logic_vector(ANGLE_WIDTH - 1 downto 0);
begin
    dut: entity work.angle_stepper
        generic map (
            ANGLE_WIDTH       => ANGLE_WIDTH,
            CLK_FREQ_HZ       => CLK_FREQ_HZ,
            ANGULAR_VEL_DEG_S => ANGULAR_VEL_DEG_S
        )
        port map (
            clk   => clk,
            rst   => rst,
            up    => up,
            down  => down,
            angle => angle
        );

    clk <= not clk after CLK_PERIOD / 2;
    
    process
    begin
        rst <= '1', '0' after CLK_PERIOD / 4;
        wait until rst = '1';
        wait until rising_edge(clk);

        -- Both pressed / released
        up   <= '1';
        down <= '1';

        wait for 100 ms;        

        up   <= '0';
        down <= '0';

        -- Up
        up <= '1';

        wait for 100 ms;

        up <= '0';
        
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Down
        down <= '1';
        
        wait;
    end process;
end;
