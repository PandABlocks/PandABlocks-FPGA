-----------------------------------------------------------------------------
--  Project      : Diamond Zebra SSI Encoder Splitter
--  Filename     : zebra_ssimstr.vhd
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

entity zebra_ssimstr is
generic (
    CHNUM           : integer  := 1;
    N               : positive := 24; -- # of encoder bits
    SSI_DEAD_PRD    : positive := 25  -- In terms of SSI clock
);
port (
    -- Global system and reset interface
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- serial interface
    smpl_shift      : in  std_logic_vector(3 downto 0);
    ssi_clk_div     : in  std_logic_vector(15 downto 0);
    ssi_sck_o       : out std_logic;
    ssi_dat_i       : in  std_logic;
    -- parallel interface
    enc_dat_o       : out std_logic_vector(N-1 downto 0);
    enc_val_o       : out std_logic;
    enc_dbg_o       : out std_logic_vector(1 downto 0)
);
end entity;

architecture rtl of zebra_ssimstr is

-- Constant declarations
constant SSI_RD_PRD     : positive := N + SSI_DEAD_PRD + 1;

-- Signal declarations
signal ssi_clk_ce       : std_logic := '1';
signal ssi_clk_p        : std_logic := '0';
signal ssi_clk_n        : std_logic := '1';
signal smpl_ce_p        : std_logic := '0';
signal smpl_ce_n        : std_logic := '1';
signal smpl_hold        : std_logic_vector(N-1 downto 0);
signal ssi_ssel         : std_logic := '1';
signal ssi_ssel_prev    : std_logic := '1';
signal ssi_ssel_rise    : std_logic;
signal prd_cnt          : integer range SSI_RD_PRD-1 downto 0;
signal smpl_sdi         : std_logic;
signal smpl_sdi_r       : std_logic;

begin

enc_dbg_o(0) <= smpl_sdi;
enc_dbg_o(1) <= smpl_sdi_r;

-- Generate SSI core clock enable from system clock
ssi_ce_gen : process(clk_i)
    variable clk_cnt    : unsigned(15 downto 0) := X"0000";
begin
    if rising_edge(clk_i) then
        if (clk_cnt =  unsigned('0' & ssi_clk_div(15 downto 1))-1) then
            ssi_clk_ce <= '1';
            clk_cnt := X"0000";
        else
            ssi_clk_ce <= '0';
            clk_cnt := clk_cnt + 1;
        end if;
    end if;
end process;

-- Generate anti phase spi clocks
ssi_clk_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (ssi_clk_ce = '1') then
            -- Antiphase spi clocks
            ssi_clk_p <= ssi_clk_n;
            ssi_clk_n <= not ssi_clk_n;
            -- Antiphase sample enables
            smpl_ce_p <= ssi_clk_n;
            smpl_ce_n <= not ssi_clk_n;
        else
            smpl_ce_p <= '0';
            smpl_ce_n <= '0';
        end if;
    end if;
end process;

-- Sample incoming SSI data on falling-edge of SSI clock.
-- Skip first smpl_ce_n pulse
smpl_sdi <= '1' when (ssi_ssel = '0' and smpl_ce_n = '1' and prd_cnt /= 0)
                else '0';

-- Programmable shifter for sample flag
smpl_shifter : SRL16
port map (
    D       => smpl_sdi,
    CLK     => clk_i,
    A0      => smpl_shift(0),
    A1      => smpl_shift(1),
    A2      => smpl_shift(2),
    A3      => smpl_shift(3),
    Q       => smpl_sdi_r
);

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ssi_sck_o <= '1';
            smpl_hold <= (others => '0');
            ssi_ssel <= '1';
            enc_dat_o <= (others => '0');
        else
            -- Period counter at SSI clock rate
            -- This includes data transmission time pluse
            -- dead period
            if (smpl_ce_p = '1') then
                if (prd_cnt = SSI_RD_PRD-1) then
                    prd_cnt <= 0;
                else
                    prd_cnt <= prd_cnt + 1;
                end if;
            end if;

            -- Generate internal select signal for N+1 SSI cycles
            -- Used to gate SSI clock output
            if (prd_cnt = 0) then
                ssi_ssel <= '0';
            elsif (prd_cnt = N + 1) then
                ssi_ssel <= '1';
            end if;

            -- Output register for SSI clock
            -- It must be '1' when there is no transmission
            if (ssi_ssel = '0') then
                ssi_sck_o <= ssi_clk_p;
            else
                ssi_sck_o <= '1';
            end if;

            -- Reads N bits
            if (ssi_ssel_rise = '1') then
                smpl_hold <= (others => '0');
            elsif (smpl_sdi_r = '1') then
                smpl_hold <= smpl_hold(N-2 downto 0) & ssi_dat_i;
            end if;

            -- Output parallel SSI data
            enc_val_o <= '0';

            if (ssi_ssel_rise = '1') then
                enc_dat_o <= smpl_hold;
                enc_val_o <= '1';
            end if;
        end if;
    end if;
end process;

--
-- Internal support signals
process(clk_i)
begin
    if rising_edge(clk_i) then
        ssi_ssel_prev <= ssi_ssel;
        ssi_ssel_rise <= ssi_ssel and not ssi_ssel_prev;
    end if;
end process;

end rtl;

