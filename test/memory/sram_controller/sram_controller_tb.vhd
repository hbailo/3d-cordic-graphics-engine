library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity sram_controller_tb is
end entity;

architecture behavioral of sram_controller_tb is
    constant CLK_FREQ  : positive := 50_000_000;
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);

    signal clk: std_logic := '0';
    signal rst: std_logic := '1';

    signal start : std_logic := '0';
    signal rw    : std_logic := '1';   -- 1 = read, 0 = write
    signal addr  : std_logic_vector(17 downto 0) := (others=>'0');
    signal din   : std_logic_vector(31 downto 0) := (others=>'0');
    signal dout  : std_logic_vector(31 downto 0);

    signal addr_a : std_logic_vector(17 downto 0);
    signal dio_a  : std_logic_vector(15 downto 0);
    signal we_n_a : std_logic;
    signal oe_n_a : std_logic;
    signal ce_n_a : std_logic;
    signal ub_n_a : std_logic;
    signal lb_n_a : std_logic;
    signal addr_b : std_logic_vector(17 downto 0);
    signal dio_b  : std_logic_vector(15 downto 0);
    signal we_n_b : std_logic;
    signal oe_n_b : std_logic;
    signal ce_n_b : std_logic;
    signal ub_n_b : std_logic;
    signal lb_n_b : std_logic;
    signal ready  : std_logic;

    constant SRAM_MOCK_ADDR_WIDTH: positive := 3;
begin
    dut: entity work.sram_controller
        port map (
            clk    => clk,
            rst    => rst,
            start  => start,
            rw     => rw,
            addr   => addr,
            din    => din,
            dout   => dout,
            ready  => ready,            
            addr_a => addr_a,
            dio_a  => dio_a,
            we_n_a => we_n_a,
            oe_n_a => oe_n_a,
            ce_n_a => ce_n_a,
            ub_n_a => ub_n_a,
            lb_n_a => lb_n_a,
            addr_b => addr_b,
            dio_b  => dio_b,
            we_n_b => we_n_b,
            oe_n_b => oe_n_b,
            ce_n_b => ce_n_b,
            ub_n_b => ub_n_b,
            lb_n_b => lb_n_b
        );

    sram_a: entity work.sram_mock
        generic map (
            ADDR_WIDTH => SRAM_MOCK_ADDR_WIDTH
        )
        port map (
            addr => addr_a,
            dio  => dio_a,
            we_n => we_n_a,
            oe_n => oe_n_a,
            ce_n => ce_n_a,
            ub_n => ub_n_a,
            lb_n => lb_n_a
        );

    sram_b: entity work.sram_mock
        generic map (
            ADDR_WIDTH => SRAM_MOCK_ADDR_WIDTH
        )        
        port map (
            addr => addr_b,
            dio  => dio_b,
            we_n => we_n_b,
            oe_n => oe_n_b,
            ce_n => ce_n_b,
            ub_n => ub_n_b,
            lb_n => lb_n_b
        );
    
    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        rst   <= '1', '0' after CLK_PERIOD / 4;
        start <= '0';
        
        wait until rst = '0';
        
        -- Write 0xDEADBEEF at address 0x02
        wait until rising_edge(clk);
        wait until rising_edge(clk);        
        
        addr  <= b"00_0000_0000_0000_0010";
        din   <= x"DEADBEEF";
        rw    <= '0';
        start <= '1';

        wait until rising_edge(clk);
        start <= '0';

        wait until ready = '1';

        -- Write 0xDEADBEEF at address 0x07
        wait until rising_edge(clk);
        wait until rising_edge(clk);        
        
        addr  <= b"00_0000_0000_0000_0111";
        din   <= x"FACEBEAD";
        rw    <= '0';
        start <= '1';

        wait until rising_edge(clk);
        start <= '0';

        wait until ready = '1';        
        
        -- Read at address 0x02
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        
        addr  <= b"00_0000_0000_0000_0010";
        rw    <= '1';
        start <= '1';

        wait until rising_edge(clk);        
        start <= '0';

        wait until ready = '1';
        wait;
    end process;
end architecture;
