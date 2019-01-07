--------------------------------------------------------------------------------
--  File:       qdecoder.vhd
--  Desc:       HDL implementation of a quadrature decoder
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity qdecoder is
port (
    -- Clock and reset signals
    clk                 : in  std_logic;
    reset               : in  std_logic;
    --Quadrature A,B and Z input
    a_i                 : in  std_logic;
    b_i                 : in  std_logic;
    --Step/Direction outputs
    quad_reset_o        : out std_logic;
    quad_trans_o        : out std_logic;
    quad_dir_o          : out std_logic
);
end qdecoder;

architecture rtl of qdecoder is

-- Quadrature 4X decoding state machine signals
signal quad_st_new          : std_logic_vector(1 downto 0);
signal quad_st_old          : std_logic_vector(1 downto 0);
signal quad_trans           : std_logic;
signal quad_dir             : std_logic;
signal quad_error           : std_logic;

-- State constants for 4x quad decoding, CH B is MSB, CH A is LSB
constant    QUAD_STATE_0    : std_logic_vector(1 downto 0) := "00";
constant    QUAD_STATE_1    : std_logic_vector(1 downto 0) := "01";
constant    QUAD_STATE_2    : std_logic_vector(1 downto 0) := "11";
constant    QUAD_STATE_3    : std_logic_vector(1 downto 0) := "10";

begin

quad_reset_o <= '0';

--------------------------------------------------------------------------
-- Read filtered values a_i, b_i and assert the quad_trans and quad_dir
-- signals
--------------------------------------------------------------------------
quad_state_proc: process(clk) begin
    if rising_edge(clk) then
        if (reset = '1') then
            quad_st_old <= (b_i & a_i);
            quad_st_new <= (b_i & a_i);
            quad_trans <= '0';
            quad_dir <= '0';
            quad_error <= '0';
        else
            quad_st_new <= (b_i & a_i);
            quad_st_old <= quad_st_new;

            case quad_st_new is
                when QUAD_STATE_0 =>    --"00"
                    case quad_st_old is
                        when QUAD_STATE_0 =>
                            quad_trans      <= '0';
                        when QUAD_STATE_3 => --"10" -- dflt positive direction
                            quad_trans  <= '1';
                            quad_dir    <= '0';
                        when QUAD_STATE_1 => --"01" -- dflt negative direction
                            quad_trans  <= '1';
                            quad_dir    <= '1';
                        when others =>
                            quad_error  <= '1';
                            quad_trans  <= '0';
                    end case; --quad_st_old

                when QUAD_STATE_1 =>    --"01"
                    case quad_st_old is
                        when QUAD_STATE_1 =>
                            quad_trans      <= '0';
                        when QUAD_STATE_0 => --"10" -- dflt positive direction
                                quad_trans  <= '1';
                                quad_dir    <= '0';
                        when QUAD_STATE_2 => --"01" -- dflt negative direction
                                quad_trans  <= '1';
                                quad_dir    <= '1';
                        when others =>
                            quad_error  <= '1';
                            quad_trans  <= '0';
                    end case; --quad_st_old

                when QUAD_STATE_2 =>    --"11"
                    case quad_st_old is
                        when QUAD_STATE_2 =>
                            quad_trans      <= '0';
                        when QUAD_STATE_1 => --"10" -- dflt positive direction
                                quad_trans  <= '1';
                                quad_dir    <= '0';
                        when QUAD_STATE_3 => --"01" -- dflt negative direction
                                quad_trans  <= '1';
                                quad_dir    <= '1';
                        when others =>
                            quad_error  <= '1';
                            quad_trans  <= '0';
                    end case; --quad_st_old

                when QUAD_STATE_3 =>    --"10"
                    case quad_st_old is
                        when QUAD_STATE_3 =>
                            quad_trans      <= '0';
                        when QUAD_STATE_2 => --"10" -- dflt positive direction
                                quad_trans  <= '1';
                                quad_dir    <= '0';
                        when QUAD_STATE_0 => --"01" -- dflt negative direction
                                quad_trans  <= '1';
                                quad_dir    <= '1';
                        when others =>
                            quad_error  <= '1';
                            quad_trans  <= '0';
                    end case; --quad_st_old

                when others =>
                    quad_error  <= '1';
                    quad_trans  <= '0';
            end case; --quad_st_new

            if (quad_trans = '1') then
                quad_trans <= '0';
            end if;

            if (quad_dir = '1') then
                quad_dir <= '0';
            end if;

            if (quad_error = '1') then
                quad_error <= '0';
            end if;
        end if;
    end if;
end process;

quad_trans_o <= quad_trans;
quad_dir_o <= quad_dir;

end architecture rtl;
