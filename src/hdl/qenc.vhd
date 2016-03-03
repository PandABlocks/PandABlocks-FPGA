--------------------------------------------------------------------------------
--  File:       panda_qenc.vhd
--  Desc:       HDL implementation of a quadrature encoder
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity panda_qenc is
port (
    -- Clock and reset signals
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    --Step/Direction outputs
    quad_trans_i        : in  std_logic;
    quad_dir_i          : in  std_logic;
    --Quadrature A,B and Z input
    a_o                 : out std_logic;
    b_o                 : out std_logic
);
end panda_qenc;

architecture rtl of panda_qenc is

-- Quadrature 4X decoding state machine signals
signal quad_st              : std_logic_vector(1 downto 0) := "00";

-- State constants for 4x quad decoding,
-- CH B is MSB, CH A is LSB
-- 0 : (+) direction
-- 1 : (-) direction
constant    QUAD_STATE_0    : std_logic_vector(1 downto 0) := "00";
constant    QUAD_STATE_1    : std_logic_vector(1 downto 0) := "01";
constant    QUAD_STATE_2    : std_logic_vector(1 downto 0) := "11";
constant    QUAD_STATE_3    : std_logic_vector(1 downto 0) := "10";

begin

a_o <= quad_st(0);
b_o <= quad_st(1);

-----------------------------------------------------------------------
--  Desc   : Toggles quadrature outputs accordingly at the user trans_i
--           rate.
-----------------------------------------------------------------------
quad_state_proc: process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            quad_st <= QUAD_STATE_0;
        elsif (quad_trans_i = '1') then
            case quad_st is
                when QUAD_STATE_0 =>    --"00"
                    if (quad_dir_i = '1') then
                        quad_st <= QUAD_STATE_3;
                    else
                        quad_st <= QUAD_STATE_1;
                    end if;

                when QUAD_STATE_1 =>    --"01"
                    if (quad_dir_i = '1') then
                        quad_st <= QUAD_STATE_0;
                    else
                        quad_st <= QUAD_STATE_2;
                    end if;

                when QUAD_STATE_2 =>    --"11"
                    if (quad_dir_i = '1') then
                        quad_st <= QUAD_STATE_1;
                    else
                        quad_st <= QUAD_STATE_3;
                    end if;

                when QUAD_STATE_3 =>    --"10"
                    if (quad_dir_i = '1') then
                        quad_st <= QUAD_STATE_2;
                    else
                        quad_st <= QUAD_STATE_0;
                    end if;

                when others =>
                    quad_st <= QUAD_STATE_0;
            end case;
        end if;
    end if;
end process;

end architecture rtl;
