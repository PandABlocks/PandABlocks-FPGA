--------------------------------------------------------------------------------
--  File:       qdec.vhd
--  Desc:       HDL implementation of a quadrature decoder
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity qdec is
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
end qdec;

architecture rtl of qdec is

-- Input buffers / filters for quadrature signals
signal quad_cha_buf         : std_logic_vector(3 downto 0);
signal quad_chb_buf         : std_logic_vector(3 downto 0);
signal quad_cha_flt         : std_logic;
signal quad_chb_flt         : std_logic;
signal quad_cha_j           : std_logic;
signal quad_cha_k           : std_logic;
signal quad_chb_j           : std_logic;
signal quad_chb_k           : std_logic;

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

--Combinatorial logic for JK flip flop filters
quad_cha_j <= quad_cha_buf(3) and quad_cha_buf(2) and quad_cha_buf(1);
quad_cha_k <= not(quad_cha_buf(3) or quad_cha_buf(2) or quad_cha_buf(1));
quad_chb_j <= quad_chb_buf(3) and quad_chb_buf(2) and quad_chb_buf(1);
quad_chb_k <= not(quad_chb_buf(3) or quad_chb_buf(2) or quad_chb_buf(1));

-----------------------------------------------------------------------
--  Process:    quad_filt_proc
--  Desc:       Digital filters for the quadrature inputs.  This is
--              implemented with serial shift registers on all inputs;
--              similar to the digital filters of the HCTL-2016.  See
--              that datasheet for more information.
--  Signals:    a_i, external input
--              b_i, external input
--              quad_cha_buf, input buffer for filtering
--              quad_chb_buf, input buffer for filtering
--              quad_cha_flt, filtered cha signal
--              quad_chb_flt, filtered chb signal
--              quad_cha_j, j signal for jk FF
--              quad_cha_k, k signal for jk FF
--  Note:       Upon reset, all buffers are filled with the values
--              present on the input pins.
-----------------------------------------------------------------------
quad_filt_proc: process(clk) begin
    if rising_edge(clk) then
        if (reset = '1') then
            quad_cha_buf <= (a_i & a_i & a_i & a_i);
            quad_chb_buf <= (b_i & b_i & b_i & b_i);
            quad_cha_flt <= a_i;
            quad_chb_flt <= b_i;
        else
            --sample inputs, place into shift registers
            quad_cha_buf <= (quad_cha_buf(2) & quad_cha_buf(1) & quad_cha_buf(0) & a_i);
            quad_chb_buf <= (quad_chb_buf(2) & quad_chb_buf(1) & quad_chb_buf(0) & b_i);

            -- JK flip flop filters
            if (quad_cha_j = '1') then
                quad_cha_flt <= '1';
            end if;
            if (quad_cha_k = '1') then
                quad_cha_flt <= '0';
            end if;
            if (quad_chb_j = '1') then
                quad_chb_flt <= '1';
            end if;
            if (quad_chb_k = '1') then
                quad_chb_flt <= '0';
            end if;
        end if;
    end if;
end process quad_filt_proc;

-----------------------------------------------------------------------
--  Process:    quad_state_proc
--  Desc:       Reads filtered values quad_cha_flt, quad_chb_flt and
--              asserts the quad_trans and quad_dir signals.
--  Signals:    quad_st_old
--              quad_st_new
--              quad_trans
--              quad_dir
--              quad_error
--  Notes:      See the datasheet for more info.
-----------------------------------------------------------------------
quad_state_proc: process(clk) begin
    if rising_edge(clk) then
        if (reset = '1') then
            quad_st_old <= (b_i & a_i);
            quad_st_new <= (b_i & a_i);
            quad_trans <= '0';
            quad_dir <= '0';
            quad_error <= '0';
        else
            quad_st_new <= (quad_chb_flt & quad_cha_flt);
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
