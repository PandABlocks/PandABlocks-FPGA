--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : A three-clock-cycle delay filter combine to reject low level
--                noise and large, short duration noise spikes that typically
--                occur in motor system applications (similar to the digital
--                filters of the HCTL-2016)
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

entity delay_filter is
port (
    -- Clock and reset signals
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    --Input and Output
    pulse_i             : in  std_logic;
    filt_o              : out std_logic
);
end delay_filter;

architecture rtl of delay_filter is

-- Pack into IOB
signal pulse_iob        : std_logic;
attribute iob           : string;
attribute iob of pulse_iob  : signal is "TRUE"; 

-- Input buffers / filters for quadrature signals
signal pulse_buf        : std_logic_vector(2 downto 0) := "000";
signal filt             : std_logic := '0';
signal jk               : std_logic_vector(1 downto 0);

attribute async_reg     : string;
attribute async_reg of pulse_buf : signal is "TRUE";

begin

--------------------------------------------------------------------------
--  Digital filters for the quadrature inputs.  This is implemented with
--  serial shift registers on all inputs.
--------------------------------------------------------------------------
shift_reg : process(clk_i) begin
    if rising_edge(clk_i) then
        pulse_iob <= pulse_i;
        --sample inputs, place into shift registers
        pulse_buf <= pulse_buf(1) & pulse_buf(0) & pulse_iob;
    end if;
end process;

-- JK flip flop inputs from 3-stage delay line
jk(1) <= pulse_buf(2) and pulse_buf(1) and pulse_buf(0);    -- J
jk(0) <= not(pulse_buf(2) or pulse_buf(1) or pulse_buf(0)); -- K

-- JK Flip Flop
FJKC : process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            filt <= '0';
        else
            case (jk) is
                when "00" => filt <= filt;
                when "01" => filt <= '0';
                when "10" => filt <= '1';
                when "11" => filt <= not filt;
                when others => filt <= filt;
            end case;
        end if;
    end if;
end process;

filt_o <= filt;

end rtl;

