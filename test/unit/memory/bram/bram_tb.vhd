library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity bram_tb is
end entity;

architecture behavioral of bram_tb is
    constant CLK_FREQ   : positive := 50_000_000;
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);

    -- DUT generics
    constant ADDR_WIDTH : positive := 3;
    constant DATA_WIDTH : positive := 32;
    
    -- DUT signals
    signal clk    : std_logic := '0';
    signal en_a   : std_logic;
    signal en_b   : std_logic;
    signal we_a   : std_logic;
    signal addr_a : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal addr_b : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal din_a  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal dout_b : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin
    dut: entity work.bram
    generic map (
        ADDR_WIDTH => ADDR_WIDTH,
        DATA_WIDTH => DATA_WIDTH
    )
    port map (
        clk    => clk,
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
        -- Write
        addr_a <= std_logic_vector(to_unsigned(3, addr_a'length));
        addr_b <= (others => '0');
        din_a  <= std_logic_vector(to_unsigned(28, din_a'length));
        we_a   <= '1';
        en_a   <= '1';
        en_b   <= '0';
        wait until rising_edge(clk);
        
        we_a   <= '0';
        en_a   <= '0';        
        wait until rising_edge(clk);

        -- Read
        addr_a <= (others => '0');
        addr_b <= std_logic_vector(to_unsigned(3, addr_a'length));
        din_a  <= (others => '0');
        we_a   <= '0';
        en_a   <= '0';
        en_b   <= '1';
        wait until rising_edge(clk);
        
        en_b   <= '0';        
        wait until rising_edge(clk);

        wait;
    end process;
end architecture;
