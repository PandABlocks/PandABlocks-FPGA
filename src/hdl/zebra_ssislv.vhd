-----------------------------------------------------------------------------
--  Project      : Diamond Zebra SSI Encoder Splitter
--  Filename     : zebra_ssislv.vhd
--  Purpose      : Absolute encoder SSI splitter
--
--  Author       : Dr. Isa Servan Uzun
-----------------------------------------------------------------------------
--  Copyright (c) 2012 Diamond Light Source Ltd.
--  All rights reserved.
-----------------------------------------------------------------------------
--  Module Description: Acts as Slave SSI to master control systems (MaxV).
--  Latched internal encoder position read by master, and shifts it over
--  serial SSI data line on incoming clocks from master. Module implements
--  a 10us bit timeout, and 25us dead time between reads.
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

entity zebra_ssislv is
generic (
    N                   : positive := 24 -- # of encoder bits
);
port (
    -- Global system and reset interface
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- serial interface
    ssi_sck_i           : in  std_logic;
    ssi_dat_o           : out std_logic;
    -- parallel interface
    enc_dat_i           : in  std_logic_vector(N-1 downto 0);
    enc_val_i           : in  std_logic;
    -- status
    ssi_rd_sof          : out std_logic
);
end entity;

architecture rtl of zebra_ssislv is

type state_t is (IDLE, TX, LAST, DEAD);

signal state                : state_t;

signal enc_dat_slr          : std_logic_vector(N-1 downto 0);
signal ssi_sck_d1           : std_logic := '1';
signal ssi_sck_d2           : std_logic := '1';
signal ssi_sck_rise         : std_logic;
signal tcount               : unsigned(9 downto 0);

begin

-- Flags start of SSI read cycle
ssi_rd_sof <= '1' when (state = IDLE and ssi_sck_d2 = '0')
                else '0';
-- Timeout counter used for keeping track of incoming
-- bits. If a new clock edge does not arrive in 512
-- clock cycles (~10us), resets the state machine
timeout_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Reset timeout counter on clock rise
        if (state = IDLE or ssi_sck_rise = '1') then
            tcount <= (others => '0');
        elsif (state = TX) then
            tcount <= tcount + 1;
        end if;
    end if;
end process;

-- Register input SSI clock
process(clk_i)
begin
    if rising_edge(clk_i) then
        ssi_sck_d1 <= ssi_sck_i;
        ssi_sck_d2 <= ssi_sck_d1;
        ssi_sck_rise <= ssi_sck_d1 and not ssi_sck_d2;
    end if;
end process;

--
-- SSI Slave State Machine
--
process(clk_i)
    variable bitcount       : integer range N downto 0;
    variable dcount         : integer range 1250 downto 0;
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            state <= IDLE;
            bitcount := 0;
            dcount := 0;
        else
            case (state) is
                -- First Low-transition indicates incoming clock stream
                when IDLE =>
                    if (ssi_sck_d2 = '0') then
                        state <= TX;
                    end if;
                    bitcount := 0;
                    dcount := 0;
                -- Keep track of incoming ssi clocks
                when TX =>
                    if (ssi_sck_rise = '1') then
                        bitcount := bitcount + 1;
                    end if;

                    -- On clock wait timeout go back to idle, OR
                    -- N bits successfully received and wait for clk='1'
                    if (tcount(9) = '1') then
                        state <= IDLE;
                    elsif (bitcount = N) then
                        state <= LAST;
                    end if;

                -- Wait for clock to be asserted to '1' by master
                when LAST =>
                    if (tcount(9) = '1') then
                        state <= IDLE;
                    elsif (ssi_sck_rise = '1') then
                        state <= DEAD;
                    end if;

                -- Wait for 25us deadtime before accepting new request
                when DEAD =>
                    dcount := dcount + 1;
                    if (dcount = 1250) then
                        state <= IDLE;
                    end if;

                when others =>

            end case;
        end if;
    end if;
end process;

-- Shift encoder data to SSI output
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            enc_dat_slr <= (others => '0');
            ssi_dat_o <= '1';
        else
            -- Latch encoder value to be shifted in idle state, and
            if (state = IDLE and ssi_sck_d2 = '0') then
                enc_dat_slr <= enc_dat_i;
            elsif (state = TX and ssi_sck_rise = '1') then
                enc_dat_slr <= enc_dat_slr(N-2 downto 0) & enc_dat_slr(N-1);
            end if;

            -- Shift bits in TX state on incoming clock
            -- Data is set to '1' during idle
            -- Data is set to '0' during dead period
            if (state = IDLE) then
                ssi_dat_o <= '1';
            elsif (state = DEAD) then
                ssi_dat_o <= '0';
            elsif (state = TX and ssi_sck_rise = '1') then
                ssi_dat_o <= enc_dat_slr(N-1);
            end if;
        end if;
    end if;
end process;

end rtl;

