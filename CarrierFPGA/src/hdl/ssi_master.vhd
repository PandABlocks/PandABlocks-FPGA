-----------------------------------------------------------------------------
--  Project      : Diamond PandA SSI Encoder Splitter
--  Filename     : ssi_master.vhd
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

library unisim;
use unisim.vcomponents.all;

entity ssi_master is
port (
    -- Global system and reset interface
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Block Parameters
    BITS            : in  std_logic_vector(7 downto 0);
    CLKRATE         : in  std_logic_vector(31 downto 0);
    FRAMERATE       : in  std_logic_vector(31 downto 0);
    -- Block Inputs and Outputs
    ssi_sck_o       : out std_logic;
    ssi_dat_i       : in  std_logic;
    posn_o          : out std_logic_vector(31 downto 0);
    posn_valid_o    : out std_logic
);
end entity;

architecture rtl of ssi_master is

-- Signal declarations
type mclk_fsm_t is (WAIT_FRAME, SYNC_TO_CLK, GEN_MCLK, DATA_OUT);
signal mclk_fsm         : mclk_fsm_t;
signal msdi_fsm         : mclk_fsm_t;

signal sclk_ce          : std_logic;
signal sfrm_ce          : std_logic;
signal sclk             : std_logic;
signal smpl_hold        : std_logic_vector(31 downto 0);
signal smpl_sdi         : std_logic;
signal mclk_cnt         : unsigned(7 downto 0);
signal CLKRATE_2x       : std_logic_vector(31 downto 0);

begin

-- Connect outputs
ssi_sck_o <= sclk;

-- Generate Internal SSI Clock (@2x freq) from system clock
CLKRATE_2x <= '0' & CLKRATE(31 downto 1);

sclk_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => reset_i,
    PERIOD      => CLKRATE_2x,
    pulse_o     => sclk_ce
);

-- Generate Internal SSI Frame from system clock
frame_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => reset_i,
    PERIOD      => FRAMERATE,
    pulse_o     => sfrm_ce
);

-- SSI Master FSM
ssi_fsm_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            sclk <= '1';
            mclk_cnt <= (others=> '0');
        else
            if (sclk_ce = '1') then
                msdi_fsm <= mclk_fsm;
            end if;

            case (mclk_fsm) is
                -- Wait for SSI frame trigger
                when WAIT_FRAME =>
                    sclk <= '1';
                    mclk_cnt <= (others=> '0');

                    if (sfrm_ce = '1') then
                        mclk_fsm <= SYNC_TO_CLK;
                    end if;

                -- Sync to next internal SSI clock
                when SYNC_TO_CLK =>
                    if (sclk_ce = '1') then
                        mclk_fsm <= GEN_MCLK;
                        sclk <= '0';
                    end if;

                -- Generate N clock pulses
                when GEN_MCLK =>
                    if (sclk_ce = '1') then
                        sclk <= not sclk;
                    end if;

                    -- Keep track of number of BITS received
                    if (sclk_ce = '1' and sclk = '0') then
                        mclk_cnt <= mclk_cnt + 1;
                        if (mclk_cnt = unsigned(BITS))then
                            mclk_fsm <= DATA_OUT;
                        end if;
                    end if;

                -- Output strobe
                when DATA_OUT =>
                    mclk_fsm <= WAIT_FRAME;

                when others =>
            end case;
        end if;
    end if;
end process;

-- Sample clock is aligned on the rising edge of next clock. This gives us
-- full clock period for propagation delay
smpl_sdi <= '1' when (msdi_fsm = GEN_MCLK and sclk_ce = '1' and sclk = '0')
                else '0';

latch_data : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posn_o <= (others => '0');
            posn_valid_o <= '0';
            smpl_hold <= (others => '0');
        else
            -- Shift-in incoming data during MCLK generation
            if (mclk_fsm = WAIT_FRAME) then
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

