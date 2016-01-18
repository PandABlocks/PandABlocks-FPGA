--------------------------------------------------------------------------------
--  File:       panda_div.vhd
--  Desc:       Dual output Pulse Divider.
--
--  Author:     Isa S. Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity panda_div is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    inp_i               : in  std_logic;
    rst_i               : in  std_logic;
    outd_o              : out std_logic;
    outn_o              : out std_logic;
    -- Block Parameters
    FIRST_PULSE         : in  std_logic;
    DIVISOR             : in  std_logic_vector(31 downto 0);
    FORCE_RST           : in  std_logic;
    -- Block Status
    COUNT               : out std_logic_vector(31 downto 0)
);
end panda_div;

architecture rtl of panda_div is

signal input_prev       : std_logic;
signal input_rise       : std_logic;
signal counter          : unsigned(31 downto 0) := (others => '0');
signal pulsmask         : std_logic;

signal DIVISOR_prev     : std_logic_vector(31 downto 0);
signal FIRST_PULSE_prev : std_logic;
signal config_reset     : std_logic;
signal reset            : std_logic;
signal rst_prev         : std_logic;
signal rst_rise         : std_logic;
signal is_first_pulse   : std_logic;

begin

-- Input Registers.
process(clk_i)
begin
    if rising_edge(clk_i) then
        DIVISOR_prev <= DIVISOR;
        FIRST_PULSE_prev <= FIRST_PULSE;
        rst_prev <= rst_i;
    end if;
end process;

-- Reset on configuration change.
rst_rise <= rst_i and not rst_prev;
config_reset <= '1' when (DIVISOR /= DIVISOR_prev or FIRST_PULSE /= FIRST_PULSE_prev) else '0';
reset <= rst_rise or FORCE_RST or config_reset;

-- Detect input pulse rising edege.
input_rise <= inp_i and not input_prev;

-- Divider function
clock_divider : process(clk_i)
begin
    if rising_edge(clk_i) then
        input_prev <= inp_i;
        if (reset = '1') then
            -- Detect that first pulse is received following a reset.
            -- This is used to ignore an incoming pulse during a reset input.
            is_first_pulse <= '0';
            -- First pulse is generated on outn_o when '0',
            -- else on outd_o
            if (FIRST_PULSE = '0') then
                counter <= (others => '0');
            else
                counter <= unsigned(DIVISOR) - 1;
            end if;
        else
            -- Raw divider generates 1 input period long
            -- pulse which is used to mask divided pulse
            if (input_rise = '1') then
                is_first_pulse <= '1';
                if (counter = unsigned(DIVISOR) - 1) then
                    counter <= (others => '0');
                    pulsmask <= '1';
                else
                    counter <= counter + 1;
                    pulsmask <= '0';
                end if;
            end if;
        end if;
    end if;
end process;

-- Mask incoming pulse train onto D and N outputs
outd_o <= input_prev and pulsmask and is_first_pulse;
outn_o <= input_prev and not pulsmask and is_first_pulse;

-- Current divider value
COUNT <= std_logic_vector(counter);

end rtl;
