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
signal counter          : unsigned(31 downto 0);
signal pulsout          : std_logic;

begin

-- Detect rising edge of input trigger signal
process(clk_i)
begin
    if rising_edge(clk_i) then
        input_prev <= inp_i;
    end if;
end process;

input_rise <= inp_i and not input_prev;

-- Divider function
clock_divider : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (rst_i = '1' or FORCE_RST = '1') then
            pulsout <= '0';

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
                if (counter = unsigned(DIVISOR) - 1) then
                    counter <= (others => '0');
                    pulsout <= '1';
                else
                    counter <= counter + 1;
                    pulsout <= '0';
                end if;
            end if;
        end if;
    end if;
end process;

-- Mask pulsout onto D and N outputs
outd_o <= input_prev and pulsout;
outn_o <= input_prev and not pulsout;

-- Current divider value
COUNT <= std_logic_vector(counter);

end rtl;
