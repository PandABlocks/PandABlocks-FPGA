--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--
--  modified on aug 29, 2020 by Valerio Bassetti, MaxIV Lab, Unversity of Lund 
--  (valerio.bassetti@maxiv.lu.se)
--------------------------------------------------------------------------------
--
--  Description : SSI Slave Interface Block.
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity ssi_slave is
port (
    -- Global system and reset interface.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Configuration interface.
    ENCODING            : in  std_logic_vector(0 downto 0);
    BITS                : in  std_logic_vector(7 downto 0);
    -- Block Input and Outputs.
    posn_i              : in  std_logic_vector(31 downto 0);
    ssi_sck_i           : in  std_logic;
    ssi_dat_o           : out std_logic
);
end entity;

architecture rtl of ssi_slave is

constant SYNCPERIOD         : natural := 125 * 5;  -- 5usec
constant MONOPERIOD         : natural := 125 * 20;

type state_t is (IDLE, SHIFTING, DATA_VALID, MONOTIME);
signal fsm_state            : state_t;

signal serial_clock         : std_logic;
signal serial_clock_prev    : std_logic;
signal shift_clock          : std_logic;
signal mono_counter         : natural range 0 to MONOPERIOD;
signal shift_reg            : std_logic_vector(31 downto 0);
signal shift_counter        : unsigned(5 downto 0);
signal link_up              : std_logic;
signal ssi_active           : std_logic;
signal data_prev            : std_logic;

begin

process (clk_i)
begin
    if (rising_edge(clk_i)) then
        serial_clock <= ssi_sck_i;
        serial_clock_prev <= serial_clock;
    end if;
end process;

-- Shift source synchronous data on the Rising egde of clock
shift_clock <= serial_clock and not serial_clock_prev;
ssi_active <= '1' when (fsm_state = SHIFTING) else '0';

-- Master asserts its clock before starting SSI transaction. This
-- is used to establish synchonisation.
serial_link_detect_inst : entity work.serial_link_detect
generic map (
    SYNCPERIOD          => SYNCPERIOD
)
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    clock_i             => serial_clock,
    active_i            => ssi_active,
    link_up_o           => link_up
);

--
-- SSI Slave State Machine
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1' or link_up = '0') then
            fsm_state <= IDLE;
            shift_counter <= (others => '0');
            mono_counter <= 0;
            ssi_dat_o <= '1';
            shift_reg <= (others => '0');
            data_prev <= '0';
        else
            case (fsm_state) is
                -- First Low-transition indicates incoming clock stream
                when IDLE =>
                    shift_counter <= (others => '0');
                    mono_counter <= 0;
                    ssi_dat_o <= '1';
                    if (ssi_sck_i = '0') then
                        fsm_state <= SHIFTING;
                        shift_reg <= posn_i;
                        data_prev <= '0';
                    end if;

                -- Keep track of incoming SSI clocks
                when SHIFTING =>
                    if (shift_clock = '1') then
                        shift_reg <= shift_reg(30 downto 0) & shift_reg(31);
                        shift_counter <= shift_counter + 1;
						if (ENCODING=c_BINARY_ENCODING) then
							ssi_dat_o <= shift_reg(to_integer(unsigned(BITS))-1);
						else
							ssi_dat_o <= data_prev xor shift_reg(to_integer(unsigned(BITS))-1);
						end if;
                                     
                        data_prev <= shift_reg(to_integer(unsigned(BITS))-1);
                    end if;

                    -- Wait for untill all N bits are received
                    if (shift_counter = unsigned(BITS) + 1) then
                        fsm_state <= MONOTIME;
                    end if;

                -- De-assert data line and wait for MONOPERIOD before
                -- accepting a request.
                when MONOTIME =>
                    ssi_dat_o <= '0';
                    mono_counter <= mono_counter + 1;
                    data_prev <= data_prev;
                    if (mono_counter = MONOPERIOD-1) then
                        fsm_state <= IDLE;
                    end if;

                when others =>

            end case;
        end if;
    end if;
end process;

end rtl;

