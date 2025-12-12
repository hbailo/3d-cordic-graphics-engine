--! @file
--! @author Hernán L. Bailo - <hbailo1995@gmail.com>
--! @date 2025
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! @brief 3D vector rotator using sequential xyz rotations
--!
--! @details
--! This entity performs 3D vector rotation over the full space using the
--! x-y-z rotation order.
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
--! - Angles:
--!   - Format:     Q0.(DATA_WIDTH - 1) fixed-point scaled radians.
--!   - Bit width:  DATA_WIDTH bits (1 sign bit + (DATA_WIDTH - 1) fractional bits)
--!   - Range:      [-π, π) where π = 2^(DATA_WIDTH - 1)
--!   - Resolution: π / 2^(DATA_WIDTH - 1) radians per LSB
--!   - Encoding:   z_actual = z_encoded * π / 2^(DATA_WIDTH - 1), where z_actual is in
--!                 radians
entity xyz_rotator is
    generic (
        --! Coordinates and angles bit width
        DATA_WIDTH : positive range 1 to 1023
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

        --! X axis rotation angle
        x_angle : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Y axis rotation angle
        y_angle : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        --! Z axis rotation angle
        z_angle : in std_logic_vector(DATA_WIDTH - 1 downto 0);

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

--! @brief Structural implementation of 3D coordinate rotator
--! @details This architecture implements a 3D rotation by cascading three CORDIC-based
--! single-axis rotators (X, Y, Z). The rotation is performed in XYZ order.
architecture structural of xyz_rotator is
    -- Intermediate vector signals between rotators
    signal x_rot_x  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y_rot_x  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z_rot_x  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal x_rot_xy : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal y_rot_xy : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal z_rot_xy : std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    --! Internal valid signals between rotators
    signal valid_rot_x  : std_logic;  --!< Valid signal after x-axis rotation
    signal valid_rot_xy : std_logic;  --!< Valid signal after y-axis rotation

    --! Array type for pipeline signal routing
    --! NOTE: the inner cordic cores have a latency of DATA_WIDTH
    type slv_vector is array(natural range <>) of std_logic_vector;
    
    signal y_angle_shift_reg: slv_vector(0 to DATA_WIDTH - 1)(DATA_WIDTH - 1 downto 0);
    signal z_angle_shift_reg: slv_vector(0 to 2 * DATA_WIDTH - 1)(DATA_WIDTH - 1 downto 0);
begin
    --! Angles shift registers for pipeline synchronization
    process(clk, rst)
    begin
        if rst then
            y_angle_shift_reg <= (others => (others => '0'));
            z_angle_shift_reg <= (others => (others => '0'));
        elsif rising_edge(clk) then
            y_angle_shift_reg <= y_angle & y_angle_shift_reg(0 to y_angle_shift_reg'right - 1);
            z_angle_shift_reg <= z_angle & z_angle_shift_reg(0 to z_angle_shift_reg'right - 1);
        end if;
    end process;
   
    --! X-axis rotator
    x_axis_rotator: entity work.axis_rotator
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            AXIS       => 'X'
        )
        port map (
            clk   => clk,
            rst   => rst,
            start => start,
            xi    => xi,
            yi    => yi,
            zi    => zi,
            angle => x_angle,
            xo    => x_rot_x,
            yo    => y_rot_x,
            zo    => z_rot_x,
            valid => valid_rot_x
        );

    --! Y-axis rotator
    y_axis_rotator: entity work.axis_rotator
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            AXIS       => 'Y'
        )
        port map (
            clk   => clk,
            rst   => rst,
            start => valid_rot_x,
            xi    => x_rot_x,
            yi    => y_rot_x,
            zi    => z_rot_x,
            angle => y_angle_shift_reg(y_angle_shift_reg'right),
            xo    => x_rot_xy,
            yo    => y_rot_xy,
            zo    => z_rot_xy,
            valid => valid_rot_xy
        );

    --! Z-axis rotator
    z_axis_rotator: entity work.axis_rotator
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            AXIS       => 'Z'
        )
        port map (
            clk   => clk,
            rst   => rst,
            start => valid_rot_xy,
            xi    => x_rot_xy,
            yi    => y_rot_xy,
            zi    => z_rot_xy,
            angle => z_angle_shift_reg(z_angle_shift_reg'right),
            xo    => xo,
            yo    => yo,
            zo    => zo,
            valid => valid
        );
end architecture;
