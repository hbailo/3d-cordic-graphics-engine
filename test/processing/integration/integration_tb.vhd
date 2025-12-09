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

    constant DATA_WIDTH : positive := 9;
    
    -- DUT signals
    signal clk        : std_logic := '0';
    signal rst        : std_logic;
    signal start_rot  : std_logic;
    signal x          : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y          : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z          : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal x_angle    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y_angle    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z_angle    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal x_rot      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y_rot      : std_logic_vector(DATA_WIDTH - 1 downto 0);    
    signal z_rot      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid_rot  : std_logic;
    signal y_proj     : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z_proj     : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid_proj : std_logic;    
begin
    rotator: entity work.xyz_rotator
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk     => clk,
            rst     => rst,
            start   => start_rot,
            xi      => x,
            yi      => y,
            zi      => z,
            x_angle => x_angle,
            y_angle => y_angle,
            z_angle => z_angle,
            xo      => x_rot,
            yo      => y_rot,
            zo      => z_rot,
            valid   => valid_rot
        );

    projector: entity work.orthographic_projector
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk   => clk,
            rst   => rst,
            start => valid_rot,
            xi    => x_rot,
            yi    => y_rot,
            zi    => z_rot,
            yo    => y_proj,
            zo    => z_proj,
            valid => valid_proj
        );    

    clk <= not clk after CLK_PERIOD / 2;

    process
        file coord_file : text open read_mode is "../../resources/data/q0.8-coordinates.csv";
        variable L      : line;
        variable vx     : integer;
        variable vy     : integer;
        variable vz     : integer;
        variable dummy  : string(1 to 1);
    begin
        rst   <= '1', '0' after CLK_PERIOD / 4;
        
        x_angle <= std_logic_vector(to_signed(143, DATA_WIDTH));
        y_angle <= std_logic_vector(to_signed(-12, DATA_WIDTH));
        z_angle <= std_logic_vector(to_signed(-197, DATA_WIDTH));
        
        readline(coord_file, L);
        
        wait until rst = '0';
        wait until rising_edge(clk);
        
        while not endfile(coord_file) loop
            readline(coord_file, L);

            -- Read integer x,y,z (comma separated)
            read(L, vx);
            read(L, dummy);   -- comma
            read(L, vy);
            read(L, dummy);   -- comma
            read(L, vz);

            start_rot <= '1';
            x <= std_logic_vector(to_signed(vx, DATA_WIDTH));
            y <= std_logic_vector(to_signed(vy, DATA_WIDTH));
            z <= std_logic_vector(to_signed(vz, DATA_WIDTH));
            
            wait until rising_edge(clk);
        end loop;
        
            start_rot <= '0';
        wait;
    end process;

    log_rot: process
        file rot_file : text open write_mode is "build/rot.txt";        
        variable L    : line;
    begin
        wait until rst = '0';
        wait until rising_edge(clk);

        while True loop
            if valid_rot = '1' then
                write(L, integer(to_integer(signed(x_rot))));
                write(L, string'(","));                                
                write(L, integer(to_integer(signed(y_rot))));
                write(L, string'(","));                                                
                write(L, integer(to_integer(signed(z_rot))));
                
                writeline(rot_file, L);
                L := null;
            end if;
            
            wait until rising_edge(clk);
        end loop;
        
        wait;
    end process;        
end architecture;
