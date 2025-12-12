--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! @brief 3D Rotation around cartesian axis
--! @details
--! This entity performs a rotation of a 3D vector (xi, yi, zi) around the AXIS axis.
--!
--! The input vector is rotated in the plane by the specified angle, leaving the AXIS component unchanged.
--!
--! Operation
--! - Rotation begins when `start` is asserted for at least one rising edge of `clk`.
--! - When the output vector (xo, yo, zo) becomes valid, output signal 'valid'
--! is asserted high for one cycle.
--!
--! Numerical Representation
--! - Cartesian coordinates (x, y, z):
--!   - Format:    Two's complement signed number
--!   - Bit width: DATA_WIDTH bits: (1 sign bit + (DATA_WIDTH - 1) magnitude bits)
--!   - Range:     [-2^(DATA_WIDTH - 1), 2^(DATA_WIDTH - 1) - 1]
--!
--! - Angle:
--!   - Format:     Q0.(DATA_WIDTH - 1) fixed-point scaled radians.
--!   - Bit width:  DATA_WIDTH bits (1 sign bit + (DATA_WIDTH - 1) fractional bits)
--!   - Range:      [-π, π) where π = 2^(DATA_WIDTH - 1)
--!   - Resolution: π / 2^(DATA_WIDTH - 1) radians per LSB
--!   - Encoding:   z_actual = z_encoded * π / 2^(DATA_WIDTH - 1), where z_actual is in
--!                 radians
entity axis_rotator is
    generic (
        --! Coordinates and angles bit width
        DATA_WIDTH : positive range 1 to 1023;
        AXIS       : character
    );
    
    port (
        --! System clock
        clk : in std_logic;

        --! Active-high asynchronous reset
        rst : in std_logic;

        --! Start signal
        start : in std_logic;

        --! X coordinate input
        xi : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Y coordinate input
        yi : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Z coordinate input
        zi : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Axis rotation angle
        angle : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! X coordinate output
        xo : out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Y coordinate output
        yo : out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Z coordinate output
        zo : out std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Valid output flag
        valid : out std_logic
    );
end entity;

--! @brief Structural architecture
--! @details
--! This architecture uses a `cordic` entity to rotate the components around
--! the selected axis.
architecture structural of axis_rotator is
    signal ui : std_logic_vector(xi'range);
    signal vi : std_logic_vector(yi'range);
    signal wi : std_logic_vector(zi'range);
    signal uo : std_logic_vector(xo'range);
    signal vo : std_logic_vector(yo'range);
    signal wo : std_logic_vector(zo'range);
    
    type slv_vector is array(natural range <>) of std_logic_vector;
    
    signal axis_comp_shift_reg: slv_vector(0 to DATA_WIDTH - 1)(DATA_WIDTH - 1 downto 0);
begin
    --! Shift register for the unchanged AXIS component 
    process(clk, rst)
    begin
        if rst then
            axis_comp_shift_reg <= (others => (others => '0'));
        elsif rising_edge(clk) then            
            axis_comp_shift_reg <= wi & axis_comp_shift_reg(0 to axis_comp_shift_reg'right - 1);
        end if;
    end process;

    wo <= axis_comp_shift_reg(axis_comp_shift_reg'right);
    
    axis_gen: case AXIS generate
        when 'X' =>
            ui <= yi;
            vi <= zi;
            wi <= xi;
            xo <= wo;
            yo <= uo;
            zo <= vo;
            
        when 'Y' =>
            ui <= zi;
            vi <= xi;
            wi <= yi;
            xo <= vo;            
            yo <= wo;
            zo <= uo;            
            
        when 'Z' =>
            ui <= xi;
            vi <= yi;
            wi <= zi;
            xo <= uo;            
            yo <= vo;
            zo <= wo;

        when others =>
            assert false 
                report "Invalid AXIS value (must be 'X','Y','Z')" 
                severity failure;
    end generate;

    plane_rotator: entity work.cordic
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk   => clk,
            rst   => rst,
            start => start,
            xi    => ui,
            yi    => vi,
            zi    => angle,
            xo    => uo,
            yo    => vo,
            zo    => open,
            valid => valid
        );
end architecture;
