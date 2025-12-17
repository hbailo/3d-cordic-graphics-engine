library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use std.env.all;
use std.textio.all;

entity csv_to_bin_converter is
end entity;

architecture behavioral of csv_to_bin_converter is
    constant DATA_WIDTH : positive := 9;    
begin
    converter: process
        file csv_file: text open read_mode is "./data/q0.8-coordinates.csv";

        type bin_file_t is file of character;
        file bin_file: bin_file_t open write_mode is "./data/q0.8-coordinates.bin";
        variable bin_buf: std_logic_vector(31 downto 0);
        
        variable line_buf : line;
        variable x        : integer;
        variable y        : integer;
        variable z        : integer;
        variable comma    : string(1 to 1);
    begin
        readline(csv_file, line_buf); -- Header line
        
        while not endfile(csv_file) loop
            readline(csv_file, line_buf);

            -- Read coordinates: x,y,z
            read(line_buf, x);
            read(line_buf, comma);
            read(line_buf, y);
            read(line_buf, comma);
            read(line_buf, z);

            -- Write binary
            bin_buf := std_logic_vector(to_signed(x, DATA_WIDTH)) &
                       std_logic_vector(to_signed(y, DATA_WIDTH)) &
                       std_logic_vector(to_signed(z, DATA_WIDTH)) &
                       "00000";
                        
            write(bin_file, character'val(to_integer(unsigned(bin_buf(31 downto 24)))));
            write(bin_file, character'val(to_integer(unsigned(bin_buf(23 downto 16)))));
            write(bin_file, character'val(to_integer(unsigned(bin_buf(15 downto 8)))));
            write(bin_file, character'val(to_integer(unsigned(bin_buf(7  downto 0)))));            
        end loop;

        file_close(csv_file);        
        file_close(bin_file);
        
        finish;
    end process; 
end architecture;
