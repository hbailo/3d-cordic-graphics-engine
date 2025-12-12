library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all; 
use ieee.math_real.all;
use std.textio.all;

entity integration_tb is
end entity;

architecture behavioral of integration_tb is
    -- Clock
    constant CLK_FREQ   : positive := 50_000_000;
    constant CLK_PERIOD : time := 1 sec / real(CLK_FREQ);

    -- DUT generics
    constant DATA_WIDTH : integer := 9;
    constant WIDTH_PX   : integer := 320;
    constant HEIGHT_PX  : integer := 320;
    constant ADDR_WIDTH : integer := integer(ceil(log2(real(WIDTH_PX * HEIGHT_PX))));
    constant LAST_ADDR  : integer := WIDTH_PX * HEIGHT_PX - 1;
    
    -- Signals
    signal clk         : std_logic := '0';
    signal rst         : std_logic;
    signal draw        : std_logic;
    signal x           : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y           : std_logic_vector(DATA_WIDTH - 1 downto 0);        
    signal clear       : std_logic;
    signal vram_we     : std_logic;
    signal vram_w_addr : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal vram_din    : std_logic;
    signal vram_r_addr : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal vram_dout   : std_logic;    
begin
    bitmap_sequencer: entity work.bitmap_sequencer
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            WIDTH_PX   => WIDTH_PX,
            HEIGHT_PX  => HEIGHT_PX
        )
        port map (
            clk       => clk,
            rst       => rst,
            draw      => draw,
            x         => x,
            y         => y,
            clear     => clear,
            vram_we   => vram_we,
            vram_addr => vram_w_addr,
            vram_din  => vram_din
        );

    vram: entity work.dual_port_ram
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => 1
        )
        port map (
            clk    => clk,
            we     => vram_we,
            addr_a => vram_w_addr,
            addr_b => vram_r_addr,
            din_a  => (0 => vram_din),
            dout_a => open,
            dout_b(0) => vram_dout
        );

    clk <= not clk after CLK_PERIOD / 2;

    process
        file coord_file : text open read_mode is "../../../resources/data/q0.8-coordinates.csv";
        variable L     : line;
        variable vx    : integer;
        variable vy    : integer;
        variable vz    : integer;
        variable dummy : string(1 to 1);
    begin
        rst   <= '1', '0' after CLK_PERIOD / 4;
        draw  <= '0';
        clear <= '0';
                
        readline(coord_file, L);
        
        wait until rst = '0';
        wait until rising_edge(clk);

        clear <= '1';
        wait until rising_edge(clk);
        clear <= '0';        
        draw  <= '1';

        readline(coord_file, L);

        -- Read integer x,y,z (comma separated)
        read(L, vx);
        read(L, dummy);   -- comma
        read(L, vy);
        read(L, dummy);   -- comma
        read(L, vz);

        -- Map CSV (y, z) → VHDL (x, y)
        x <= std_logic_vector(to_signed(vy, DATA_WIDTH));
        y <= std_logic_vector(to_signed(vz, DATA_WIDTH));
        
        wait until vram_din = '1';
        
        while not endfile(coord_file) loop
            readline(coord_file, L);

            -- Read integer x,y,z (comma separated)
            read(L, vx);
            read(L, dummy);   -- comma
            read(L, vy);
            read(L, dummy);   -- comma
            read(L, vz);

            -- Map CSV (y, z) to VHDL (x, y)
            x <= std_logic_vector(to_signed(vy, DATA_WIDTH));
            y <= std_logic_vector(to_signed(vz, DATA_WIDTH));

            wait until rising_edge(clk);
        end loop;
        
        draw <= '0';
        wait;
    end process;

    dump_vram: process
        file dump_file : text open write_mode is "vram_dump.txt";        
        variable L    : line;
    begin
        wait until rst = '0';
        wait until rising_edge(clk);
        
        wait until vram_we = '0' and draw = '0' and clear = '0';
        wait until rising_edge(clk);
        
        for y_px in 0 to HEIGHT_PX - 1 loop
            for x_px in 0 to WIDTH_PX - 1 loop
                vram_r_addr <= std_logic_vector(to_unsigned(y_px * WIDTH_PX + x_px, vram_r_addr'length));
                wait until rising_edge(clk);
                wait until rising_edge(clk);

                write(L, vram_dout);
                write(L, string'(" "));
            end loop;

            writeline(dump_file, L);
            L := null;
        end loop;
        
        wait;
    end process;    
end architecture;
