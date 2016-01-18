-----------------------------------------------------------------------------
--  Project      : Diamond PandA SSI Encoder Splitter
--  Filename     : panda_ssimstr.vhd
--  Purpose      : Absolute encoder SSI Master
--
--  Author       : Dr. Isa Servan Uzun
-----------------------------------------------------------------------------
--  Copyright (c) 2012 Diamond Light Source Ltd.
--  All rights reserved.
-----------------------------------------------------------------------------
--  Module Description: Master SSI module continuously reads from Absolute
--  encoders acting as slaves. N clock cycles are generated, and on falling edge
--  of each clock, data input is latched and shifted into N-bit register.
-----------------------------------------------------------------------------
--  Limitations & Assumptions:
-----------------------------------------------------------------------------
--  Known Errors: This design is still under test. Please send any bug
--reports to isa.uzun@diamond.ac.uk
-----------------------------------------------------------------------------
--  TO DO List:
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--library work;
--use work.zebra_defines.all;
--use work.zebra_addr_defines.all;
--use work.zebra_version.all;

library unisim;
use unisim.vcomponents.all;

entity panda_ssimstr is
port (
    -- Global system and reset interface
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- serial interface
    enc_bits_i      : in  std_logic_vector(7 downto 0);
    enc_presc_i     : in  std_logic_vector(15 downto 0);
    enc_rate_i      : in  std_logic_vector(15 downto 0);
    ssi_sck_o       : out std_logic;
    ssi_dat_i       : in  std_logic;
    -- parallel interface
    posn_o          : out std_logic_vector(31 downto 0);
    posn_valid_o    : out std_logic
);
end entity;

architecture rtl of panda_ssimstr is

-- Signal declarations
type mclk_fsm_t is (WAIT_FRAME_TRIG, SYNC_TO_CLK, GEN_MCLK, DATA_OUT);
signal mclk_fsm         : mclk_fsm_t;
signal msdi_fsm         : mclk_fsm_t;

signal ssi_clk_ce       : std_logic := '0';
signal ssi_frame_ce     : std_logic := '0';
signal ssi_clk_p        : std_logic := '1';
signal smpl_hold        : std_logic_vector(31 downto 0);
signal smpl_sdi         : std_logic;
signal mclk_cnt         : unsigned(7 downto 0) := X"00";
signal clk_cnt          : unsigned(15 downto 0) := X"0000";
signal frame_cnt        : unsigned(15 downto 0) := X"0000";

begin

-- Connect outputs
ssi_sck_o <= ssi_clk_p;

-- Generate SSI core clock enable from system clock
ssi_clk_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ssi_clk_ce <= '0';
            clk_cnt <= X"0000";
        else
            if (clk_cnt =  unsigned('0' & enc_presc_i(15 downto 1))-1) then
                ssi_clk_ce <= '1';
                clk_cnt <= X"0000";
            else
                ssi_clk_ce <= '0';
                clk_cnt <= clk_cnt + 1;
            end if;
        end if;
    end if;
end process;

-- Generate Internal Frame Pulse in units of [enc_presc]
ssi_frame_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ssi_frame_ce <= '0';
            frame_cnt <= X"0000";
        else
            if (ssi_clk_ce = '1') then
                if (frame_cnt =  unsigned(enc_rate_i(14 downto 0) & '0')) then
                    ssi_frame_ce <= '1';
                    frame_cnt <= X"0000";
                else
                    ssi_frame_ce <= '0';
                    frame_cnt <= frame_cnt + 1;
                end if;
            end if;
        end if;
    end if;
end process;

-- SSI Master FSM
ssi_fsm_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            ssi_clk_p <= '1';
            mclk_cnt <= X"00";
        else
            if (ssi_clk_ce = '1') then
                msdi_fsm <= mclk_fsm;
            end if;

            case (mclk_fsm) is
                -- Wait for internal or external frame trigger
                when WAIT_FRAME_TRIG =>
                    ssi_clk_p <= '1';
                    mclk_cnt <= X"00";

                    if (ssi_frame_ce = '1') then
                        mclk_fsm <= SYNC_TO_CLK;
                    end if;

                -- Sync to next internal ssi clock
                when SYNC_TO_CLK =>
                    if (ssi_clk_ce = '1') then
                        mclk_fsm <= GEN_MCLK;
                        ssi_clk_p <= '0';
                    end if;

                -- Generate N clock pulses
                when GEN_MCLK =>
                    if (ssi_clk_ce = '1') then
                        ssi_clk_p <= not ssi_clk_p;
                        mclk_cnt <= mclk_cnt + 1;
                        -- clk_ce ticks are every half period, so count 2*BITS
                        if (mclk_cnt = unsigned(enc_bits_i(7 downto 0) & '0')) then
                            mclk_fsm <= DATA_OUT;
                        end if;
                    end if;

                -- Output strobe
                when DATA_OUT =>
                    mclk_fsm <= WAIT_FRAME_TRIG;

                when others =>
            end case;
        end if;
    end if;
end process;

-- Sample clock is aligned on the rising edge of next clock. This gives us
-- full clock period for propagation delay
smpl_sdi <= '1' when (msdi_fsm = GEN_MCLK and ssi_clk_ce = '1' and ssi_clk_p = '0') else '0';

latch_data : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posn_o <= (others => '0');
            posn_valid_o <= '0';
            smpl_hold <= (others => '0');
        else
            -- Shift-in incoming data during MCLK generation
            if (mclk_fsm = WAIT_FRAME_TRIG) then
                smpl_hold <= (others => '0');
            elsif (mclk_fsm = GEN_MCLK) then
                if (smpl_sdi = '1') then
                    smpl_hold <= smpl_hold(30 downto 0) & ssi_dat_i;
                end if;
            end if;

            -- Latch posn output at the end of frame
            if (mclk_fsm = DATA_OUT) then
                posn_o <= smpl_hold;
                posn_valid_o <= '1';
            else
                posn_valid_o <= '0';
            end if;
        end if;
    end if;
end process;

end rtl;

