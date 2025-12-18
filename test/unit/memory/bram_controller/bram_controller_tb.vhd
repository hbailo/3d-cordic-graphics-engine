library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity bram_controller_tb is
end entity;

architecture behavioral of bram_controller_tb is
    constant CLK_FREQ  : positive := 50_000_000;
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);

    -- DUT generics
    constant ADDR_WIDTH: positive := 3;
    
    -- DUT signals
    signal clk: std_logic := '0';
    signal rst: std_logic;

    signal start : std_logic := '0';
    signal rw    : std_logic;         -- 1 = read, 0 = write
    signal addr  : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal din   : std_logic_vector(31 downto 0) := (others => '0');
    signal dout  : std_logic_vector(31 downto 0);

    signal en_a   : std_logic;
    signal en_b   : std_logic;
    signal we_a   : std_logic;
    signal addr_a : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal addr_b : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal din_a  : std_logic_vector(31 downto 0);
    signal dout_b : std_logic_vector(31 downto 0);
    signal ready  : std_logic;
begin
    dut: entity work.bram_controller
        generic map (
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk    => clk,
            rst    => rst,
            start  => start,
            rw     => rw,
            addr   => addr,
            din    => din,
            dout   => dout,
            ready  => ready,            
            en_a   => en_a,
            en_b   => en_b,
            we_a   => we_a,
            addr_a => addr_a,
            addr_b => addr_b,
            din_a  => din_a,
            dout_b => dout_b
        );
    
    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        rst   <= '1', '0' after CLK_PERIOD / 4;
        start <= '0';
        
        wait until rst = '0';
        
        -- Write
        wait until rising_edge(clk);
        wait until rising_edge(clk);        
        
        addr  <= std_logic_vector(to_unsigned(3, addr'length));
        din   <= x"DEADBEEF";
        rw    <= '0';
        start <= '1';

        wait until rising_edge(clk);
        start <= '0';

        wait until ready = '1';

        -- Write
        wait until rising_edge(clk);
        wait until rising_edge(clk);        
        
        addr  <= std_logic_vector(to_unsigned(7, addr'length));
        din   <= x"FACEBEAD";
        rw    <= '0';
        start <= '1';

        wait until rising_edge(clk);
        start <= '0';

        wait until ready = '1';        
        
        -- Read
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        
        addr  <= std_logic_vector(to_unsigned(3, addr'length));
        rw    <= '1';
        start <= '1';

        wait until rising_edge(clk);        
        start <= '0';

        wait until ready = '1';
            
        wait;
    end process;
end architecture;
