-----------------------------------------------------------------------------
--  Project      : Diamond Zebra SSI Encoder Splitter
--  Filename     : ssislv.vhd
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
--  reports to isa.uzun@diamond.ac.uk
-----------------------------------------------------------------------------
--  TO DO List:
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ssislv is
generic (
    N                   : positive := 24 -- # of encoder bits
);
port (
    -- Global system and reset interface
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Configuration interface
    enc_bits_i          : in  std_logic_vector(7 downto 0);
    -- serial interface
    ssi_sck_i           : in  std_logic;
    ssi_dat_o           : out std_logic;
    -- parallel interface
    posn_i              : in  std_logic_vector(31 downto 0)
);
end entity;

architecture rtl of ssislv is

constant SYNCPERIOD         : natural := 125 * 5;  -- 5usec

type state_t is (sync, idle, shifting, data_valid);
signal sh_state             : state_t;

signal sync_counter         : natural range 0 to SYNCPERIOD;
signal shift_out            : std_logic_vector(31 downto 0);
signal sclk                 : std_logic;
signal sclk_prev            : std_logic;
signal sclk_rise            : std_logic;
signal sh_counter           : unsigned(5 downto 0);
signal link_up              : std_logic;

begin

-- Register input SSI clock
process(clk_i)
begin
    if rising_edge(clk_i) then
        sclk <= ssi_sck_i;
        sclk_prev <= sclk;
    end if;
end process;

sclk_rise <= sclk and not sclk_prev;

process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset_i = '1') then
            link_up <= '0';
            sync_counter <= 0;
        else
            -- Sync counter keeps track of sclk_i in two states.
            -- Transition to idle state makes sure that a reset is applied.
            if (sh_state = sync) then
                if (sclk = '1') then
                    sync_counter <= sync_counter + 1;
                else
                    sync_counter <= 0;
                end if;

                -- Link is up.
                if (sync_counter = SYNCPERIOD-1) then
                    link_up <= '1';
                    sync_counter <= 0;
                end if;
            -- Shifting state, look for clock transitions.
            elsif (sh_state = shifting) then
                if (sclk_rise = '1') then
                    sync_counter <= 0;
                else
                    sync_counter <= sync_counter + 1;
                end if;

                -- Link is lost.
                if (sync_counter = SYNCPERIOD-1) then
                    link_up <= '0';
                    sync_counter <= 0;
                end if;
            else
                sync_counter <= 0;
            end if;
        end if;
    end if;
end process;

--
-- SSI Slave State Machine
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            sh_state <= SYNC;
            sh_counter <= (others => '0');
        else
            case (sh_state) is
                -- Detect 
                when SYNC =>
                    sh_counter <= (others => '0');
                    if (link_up = '1') then
                        sh_state <= idle;
                    end if;

                -- First Low-transition indicates incoming clock stream
                when idle =>
                    sh_counter <= (others => '0');
                    if (sclk_prev = '0') then
                        sh_state <= shifting;
                    end if;

                -- Keep track of incoming ssi clocks
                when shifting =>
                    if (sclk_rise = '1') then
                        sh_counter <= sh_counter + 1;
                    end if;

                    -- On clock wait timeout go back to idle, OR
                    -- N bits successfully received and wait for clk='1'
                    if (link_up = '0') then
                        sh_state <= sync;
                    elsif (sh_counter = unsigned(enc_bits_i) + 1) then
                        sh_state <= data_valid;
                    end if;

                -- Wait for clock to be asserted to '1' by master
                when data_valid =>
                        sh_state <= idle;

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
            shift_out <= (others => '0');
            ssi_dat_o <= '1';
        else
            -- Latch encoder value to be shifted in idle sh_state, and
            if (sh_state = idle and sclk_prev = '0') then
                shift_out <= posn_i;
            elsif (sh_state = shifting and sclk_rise = '1') then
                shift_out <= shift_out(30 downto 0) & shift_out(31);
            end if;

            -- Shift bits in shifting sh_state on incoming clock
            -- Data is set to '1' during idle
            -- Data is set to '0' during dead period
            if (sh_state = idle) then
                ssi_dat_o <= '1';
            elsif (sh_state = data_valid) then
                ssi_dat_o <= '0';
            elsif (sh_state = shifting and sclk_rise = '1') then
                ssi_dat_o <= shift_out(to_integer(unsigned(enc_bits_i))-1);
            end if;
        end if;
    end if;
end process;

end rtl;

