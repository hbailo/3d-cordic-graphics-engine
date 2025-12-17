library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use std.env.all;
use std.textio.all;

entity bin_to_csv_converter is
end entity;

architecture behavioral of bin_to_csv_converter is
    constant DATA_WIDTH: positive := 9;    
begin
    converter: process
        file csv_file: text open write_mode is "./data/q0.8-coordinates-conv-out.csv";

        type bin_file_t is file of character;
        file bin_file: bin_file_t open read_mode is "./data/q0.8-coordinates.bin";
        
        variable byte1: character;
        variable byte2: character;
        variable byte3: character;
        variable byte4: character;
        variable word32: std_logic_vector(31 downto 0);
        
        variable line_buf : line;
        variable x        : integer;
        variable y        : integer;
        variable z        : integer;
    begin
        -- Write header
        write(line_buf, string'("x,y,z"));
        writeline(csv_file, line_buf);
        
        while not endfile(bin_file) loop
            read(bin_file, byte1);
            read(bin_file, byte2);
            read(bin_file, byte3);
            read(bin_file, byte4);

            word32 := std_logic_vector(to_unsigned(character'pos(byte1), 8)) & 
                      std_logic_vector(to_unsigned(character'pos(byte2), 8)) &
                      std_logic_vector(to_unsigned(character'pos(byte3), 8)) &
                      std_logic_vector(to_unsigned(character'pos(byte4), 8));            

            -- Extract 9-bit coordinates
            x := to_integer(signed(word32(31 downto 23)));
            y := to_integer(signed(word32(22 downto 14)));
            z := to_integer(signed(word32(13 downto 5)));

            -- Write CSV line
            write(line_buf, x);
            write(line_buf, string'(","));
            write(line_buf, y);
            write(line_buf, string'(","));
            write(line_buf, z);
            
            writeline(csv_file, line_buf);        
        end loop;

        file_close(csv_file);        
        file_close(bin_file);
        
        finish;
    end process; 
end architecture;
