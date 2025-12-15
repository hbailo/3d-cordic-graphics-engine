library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity cordic_stage_tb is
end ;

architecture behavioral of cordic_stage_tb is
    constant CLK_FREQ   : positive := 50_000_000;
    constant CLK_PERIOD : time   := 1 sec / CLK_FREQ;

    constant DATA_WIDTH : positive := 9;
    constant ITERS      : positive := DATA_WIDTH - 2;  -- Total number of iterations
    constant I          : natural  := ITERS - 1;       -- Current rotation iteration

    constant PI_OVER_4 : signed(DATA_WIDTH - 1 downto 0) := to_signed(2**(DATA_WIDTH - 3), DATA_WIDTH);
    
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
    dut: entity work.cordic_stage
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ITERS      => ITERS,
            I          => I
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

        -- Case 1
        wait until rising_edge(clk);
        xi <= std_logic_vector(to_signed(99, DATA_WIDTH));
        yi <= std_logic_vector(to_signed(-33, DATA_WIDTH));
        zi <= std_logic_vector(PI_OVER_4);
        
        wait;
    end process;
end;
