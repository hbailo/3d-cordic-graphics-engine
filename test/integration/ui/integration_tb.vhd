library ieee;
use ieee.std_logic_1164.all;

entity integration_tb is
end entity;

architecture behavioral of integration_tb is
    constant CLK_FREQ_HZ   : positive := 5_000;
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ_HZ);

    constant DATA_WIDTH : positive := 9;
    constant DEBOUNCE_PERIOD_MS : positive := 20;
    constant ANGULAR_VEL_DEG_S : positive := 45;
    
    signal clk: std_logic := '0';
    signal rst: std_logic;
    
    signal x_angle: std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal x_angle_up_sw: std_logic := '0';
    signal x_angle_up: std_logic;
    signal x_angle_down_sw: std_logic := '0';    
    signal x_angle_down: std_logic;

    signal y_angle: std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y_angle_up_sw: std_logic := '0';
    signal y_angle_up: std_logic;
    signal y_angle_down_sw: std_logic := '0';    
    signal y_angle_down: std_logic;
    
    signal z_angle: std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z_angle_up_sw: std_logic := '0';
    signal z_angle_up: std_logic;
    signal z_angle_down_sw: std_logic := '0';
    signal z_angle_down: std_logic;
begin
    x_angle_up_sw_db: entity work.switch_debouncer
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS
        )
        port map (
            clk   => clk,
            rst   => rst,
            sw    => x_angle_up_sw,
            sw_db => x_angle_up
        );
    
    x_angle_down_sw_db: entity work.switch_debouncer
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS
        )
        port map (
            clk   => clk,
            rst   => rst,
            sw    => x_angle_down_sw,
            sw_db => x_angle_down
        );
    
    x_angle_stepper: entity work.angle_stepper
        generic map (
            ANGLE_WIDTH       => DATA_WIDTH,
            CLK_FREQ_HZ       => CLK_FREQ_HZ,
            ANGULAR_VEL_DEG_S => ANGULAR_VEL_DEG_S            
        )
        port map (
            clk   => clk,
            rst   => rst,
            up    => x_angle_up,
            down  => x_angle_down,
            angle => x_angle
        );

    y_angle_up_sw_db: entity work.switch_debouncer
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS
        )
        port map (
            clk   => clk,
            rst   => rst,
            sw    => y_angle_up_sw,
            sw_db => y_angle_up
        );
    
    y_angle_down_sw_db: entity work.switch_debouncer
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS
        )
        port map (
            clk   => clk,
            rst   => rst,
            sw    => y_angle_down_sw,
            sw_db => y_angle_down
        );
    
    y_angle_stepper: entity work.angle_stepper
        generic map (
            ANGLE_WIDTH       => DATA_WIDTH,
            CLK_FREQ_HZ       => CLK_FREQ_HZ,
            ANGULAR_VEL_DEG_S => ANGULAR_VEL_DEG_S 
        )
        port map (
            clk   => clk,
            rst   => rst,
            up    => y_angle_up,
            down  => y_angle_down,
            angle => y_angle
        );

    z_angle_up_sw_db: entity work.switch_debouncer
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS
        )
        port map (
            clk   => clk,
            rst   => rst,
            sw    => z_angle_up_sw,
            sw_db => z_angle_up
        );
    
    z_angle_down_sw_db: entity work.switch_debouncer
        generic map (
            CLK_FREQ_HZ        => CLK_FREQ_HZ,
            DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS
        )
        port map (
            clk   => clk,
            rst   => rst,
            sw    => z_angle_down_sw,
            sw_db => z_angle_down
        );
    
    z_angle_stepper: entity work.angle_stepper
        generic map (
            ANGLE_WIDTH       => DATA_WIDTH,
            CLK_FREQ_HZ       => CLK_FREQ_HZ,
            ANGULAR_VEL_DEG_S => ANGULAR_VEL_DEG_S 
        )
        port map (
            clk   => clk,
            rst   => rst,
            up    => z_angle_up,
            down  => z_angle_down,
            angle => z_angle
        );        

    clk <= not clk after CLK_PERIOD / 2;
    rst <= '1', '0' after CLK_PERIOD / 4;
    
    -- X angle buttons
    process
    begin
        wait until rst = '1';
        wait until rising_edge(clk);
        
        x_angle_up_sw <= '1';
        wait for 1 sec;
        x_angle_up_sw <= '0';

        wait;
    end process;

    -- Y angle buttons
    process
    begin
        wait until rst = '1';
        wait until rising_edge(clk);
        
        y_angle_down_sw <= '1';
        wait for 250 ms;
        y_angle_down_sw <= '0';

        wait;
    end process;

    -- Z angle buttons
    process
    begin
        wait until rst = '1';
        wait until rising_edge(clk);
        
        z_angle_up_sw <= '1';
        wait for 200 ms;
        z_angle_up_sw   <= '0';
        z_angle_down_sw <= '1';        
        wait for 50 ms;
        z_angle_down_sw <= '0';                
        wait;
    end process;    
end architecture;
