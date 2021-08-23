--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Serial Interface Link Detect.
--                Logic is based on the assumption that Master asserts its clock
--                for at least 5usec before starting a new transaction.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity serial_link_detect is
generic (
    SYNCPERIOD         : natural := 125 * 5 -- 5usec
);
port (
    -- Global system and reset interface.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Configuration interface.
    clock_i             : in  std_logic;
    active_i            : in  std_logic;
    link_up_o           : out std_logic
);
end entity;

architecture rtl of serial_link_detect is

signal sync_counter         : natural range 0 to SYNCPERIOD;
signal clock_prev           : std_logic;
signal clock_rise           : std_logic;
signal link_up              : std_logic;

begin

link_up_o <= link_up;

-- Clock enable on the rising edge of master clock.
clock_rise <= clock_i and not clock_prev;

link_detect : process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset_i = '1') then
            link_up <= '0';
            sync_counter <= 0;
            clock_prev <= '0';
        else
            clock_prev <= clock_i;
            -- Master asserts its Clock output for a defined period of time
            -- per spec.
            if (link_up = '0') then
                if (clock_i = '1') then
                    sync_counter <= sync_counter + 1;
                else
                    sync_counter <= 0;
                end if;

                -- Link is up.
                if (sync_counter = SYNCPERIOD-1) then
                    link_up <= '1';
                    sync_counter <= 0;
                end if;
            -- In active state, Master must keep sending clocks until all bits
            -- are received.
            elsif (active_i = '1') then
                if (clock_rise = '1') then
                    sync_counter <= 0;
                else
                    sync_counter <= sync_counter + 1;
                end if;

                -- Link is lost if there is no clock pulse is received
                -- withing SYNCPERIOD.
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

end rtl;

