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

library unisim;
use unisim.vcomponents.all;

entity panda_slow_rx is
generic (
    AW              : natural := 10;
    DW              : natural := 32;
    CLKDIV          : natural := 125
);
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Transaction interface
    rd_adr_o        : out std_logic_vector(AW-1 downto 0);
    rd_dat_o        : out std_logic_vector(DW-1 downto 0);
    rd_val_o        : out std_logic;
    -- Serial Physical interface
    spi_sclk_i      : in  std_logic;
    spi_dat_i       : in  std_logic
);
end panda_slow_rx;

architecture rtl of panda_slow_rx is

-- Ticks in terms of internal serial clock period.
-- SysClk / CLKDIV
constant SYNCPERIOD             : natural := 5; -- 5usec

type sh_states is (sync, idle, shifting, data_valid);
signal sh_state                 : sh_states;

signal shift_in                 : std_logic_vector(AW+DW-1 downto 0);

signal sh_counter               : unsigned(5 downto 0);

signal sclk_ce                  : std_logic;
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
        sclk <= spi_sclk_i;
        sdi <= spi_dat_i;
        sclk_prev <= sclk;
    end if;
end process;

sclkn_fall <= not sclk and sclk_prev;

--
-- Presclaed clock to be used internally.
--
process (clk_i)
    variable clk_div : natural range 0 to CLKDIV;
begin
    if (rising_edge(clk_i)) then
        if (reset_i = '1') then
            clk_div := 0;
            sclk_ce <= '0';
        else
            if (clk_div = CLKDIV - 1) then
                clk_div := 0;
                sclk_ce <= '1';
            else
                clk_div := clk_div + 1;
                sclk_ce <= '0';
            end if;
        end if;
    end if;
end process;

--
-- State machine has to first synchronise with the master for successfull data
-- receipt.
-- This is achived by having Idle state of 5used between data transfers.
--
Link_Manager : process (clk_i)
    variable sync_counter : natural range 0 to SYNCPERIOD;
begin
    if (rising_edge(clk_i)) then
        if (reset_i = '1') then
            link_up <= '0';
            sync_counter := 0;
        else
            -- In Sync state:
            -- We need to catch the link while there is not incoming data, so
            -- Catch sclk = '1' for SYNCPERIOD, and then set link up.
            if (sh_state = sync) then
                -- A received clock indicates we are in the middle of an SSI
                -- transaction, so wait until it is finished.
                if (sclkn_fall = '1') then
                    sync_counter := 0;
                elsif (sclk_ce = '1' and sclk = '1') then
                    sync_counter := sync_counter + 1;
                end if;
            -- In Shifting state:
            -- It means that we started SSI transaction, and we need to make 
            -- sure that we receive all the clocks.
            elsif (sh_state = shifting) then
                if (sclkn_fall = '1') then
                    sync_counter := 0;
                elsif (sclk_ce = '1') then
                    sync_counter := sync_counter + 1;
                end if;
            else
                sync_counter := 0;
            end if;

            -- Set the Link Up when we are once synced. Link will go down,
            -- if data comms is broken.
            if (sh_state = sync and sync_counter = SYNCPERIOD-1) then
                link_up <= '1';
            elsif (sh_state = shifting and sync_counter = SYNCPERIOD-1) then
                link_up <= '0';
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
            sh_counter <= (others => '0');
            shift_in <= (others => '0');
            rd_adr_o <= (others => '0');
            rd_dat_o <= (others => '0');
            rd_val_o <= '0';
        else
            -- Main state machine
            case sh_state is
                -- Sync to incoming stream by monitoring sclk_i = '1'
                -- status for SYNCPERIOD.
                when sync =>
                    sh_counter <= (others => '0');
                    rd_val_o <= '0';
                    if (link_up = '1') then
                        sh_state <= idle;
                    end if;

                -- Wait for falling edge on sclk input indicating start 
                -- of transaction.
                when idle =>
                    sh_counter <= (others => '0');
                    rd_val_o <= '0';
                    if (sclkn_fall = '1') then
                        sh_state <= shifting;
                    end if;

                -- Keep track of clock outputs and shift data out
                when shifting =>
                    if (sclkn_fall = '1') then
                        shift_in <= shift_in(AW+DW-2 downto 0) & sdi;
                        sh_counter <= sh_counter + 1;
                    end if;

                    -- Monitor link status
                    if (link_up = '0') then
                        sh_state <= sync;
                    elsif (sclkn_fall = '1' and sh_counter = AW+DW-1) then
                        sh_state <= data_valid;
                    end if;

                -- Assert data valid pulse.
                when data_valid =>
                    rd_adr_o <= shift_in(AW+DW-1 downto DW);
                    rd_dat_o <= shift_in(DW-1 downto 0);
                    rd_val_o <= '1';
                    sh_state <= idle;

                when others =>
                    sh_state <= idle;
            end case;
        end if;
    end if;
end process;

end rtl;
