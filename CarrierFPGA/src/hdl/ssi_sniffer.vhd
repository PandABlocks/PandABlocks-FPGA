--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Serial Interface Synchronous Recevier core.
--                Manages link status, and receives incoming SPI transaction,
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity ssi_sniffer is
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Configuration interface
    BITS            : in  std_logic_vector(7 downto 0);
    -- Physical SSI interface
    ssi_sck_i       : in  std_logic;
    ssi_dat_i       : in  std_logic;
    -- Block outputs
    posn_o          : out std_logic_vector(31 downto 0)
);
end ssi_sniffer;

architecture rtl of ssi_sniffer is

-- Ticks in terms of internal serial clock period.
constant SYNCPERIOD             : natural := 125 * 5; -- 5usec

type sh_states is (sync, idle, shifting, data_valid);
signal sh_state                 : sh_states;

signal shift_in                 : std_logic_vector(31 downto 0);

signal sync_counter             : natural range 0 to SYNCPERIOD;
signal shift_counter            : unsigned(5 downto 0);

signal link_up                  : std_logic;
signal sdi                      : std_logic;
signal sclk                     : std_logic;
signal sclk_prev                : std_logic;
signal sclkn_fall               : std_logic;

begin

--
-- Register inputs and detect rise/fall edges.
--
process (clk_i)
begin
    if (rising_edge(clk_i)) then
        sclk <= ssi_sck_i;
        sdi <= ssi_dat_i;
        sclk_prev <= sclk;
    end if;
end process;

sclkn_fall <= not sclk and sclk_prev;

--
-- State machine has to first synchronise with the master for successfull data
-- receipt.
-- This is achived by having Idle state of 5used between data transfers.
--
Link_Manager : process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset_i = '1') then
            link_up <= '0';
            sync_counter <= 0;
        else
            -- In Sync state:
            -- We need to catch the link while there is not incoming data, so
            -- Catch sclk = '1' for SYNCPERIOD, and then set link up.
            if (sh_state = sync) then
                -- SCLK=0 indicates an ongoing transaction, so counter is reset.
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

            -- In Shifting state:
            -- It means that we started SSI transaction, and we need to make 
            -- sure that we receive all the clocks.
            elsif (sh_state = shifting) then
                if (sclkn_fall = '1') then
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
-- Serial Receive State Machine
--
process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset_i = '1') then
            shift_counter <= (others => '0');
            shift_in <= (others => '0');
        else
            -- Main state machine
            case sh_state is
                -- Sync to incoming stream by monitoring sclk_i = '1'
                -- status for SYNCPERIOD.
                when sync =>
                    if (link_up = '1') then
                        sh_state <= idle;
                    end if;

                -- Wait for falling edge on sclk input indicating start 
                -- of transaction.
                when idle =>
                    if (sclkn_fall = '1') then
                        sh_state <= shifting;
                    end if;

                -- Keep track of clock outputs and shift data out
                when shifting =>
                    if (sclkn_fall = '1') then
                        shift_in <= shift_in(30 downto 0) & sdi;
                        shift_counter <= shift_counter + 1;
                    end if;

                    -- Monitor link status
                    if (link_up = '0') then
                        sh_state <= sync;
                        shift_in <= (others => '0');
                        shift_counter <= (others => '0');
                    elsif (sclkn_fall = '1' and shift_counter = unsigned(BITS)-1) then
                        sh_state <= data_valid;
                    end if;

                -- Latch and assert data valid pulse.
                when data_valid =>
                    posn_o <= shift_in;
                    sh_state <= idle;
                    shift_in <= (others => '0');
                    shift_counter <= (others => '0');

                when others =>
                    sh_state <= idle;
                    shift_in <= (others => '0');
                    shift_counter <= (others => '0');
            end case;
        end if;
    end if;
end process;

end rtl;
