-------------------------------------------------------------------------------
-- Two steps delay:
-- 1. Generate a 1/4 tick delay using 4x clock and select the right phase using
--   oct_delay_i(2 downto 1)
-- 2. Generate a 1/2 of each 1/4 tick delay using ODDR and select the right
--   phase using oct_delay_i(0)
--
-- This allows to generate delays from 0 to 7/8 tick with 1/8 tick step
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity oct_finedelay is
port (
    -- Main clock
    clk_i : in std_logic;
    clk_4x_i : in std_logic;
    oct_delay_i : in std_logic_vector(2 downto 0);
    signal_i : in std_logic;
    signal_o : out std_logic
);
end;

architecture rtl of oct_finedelay is
    signal in_signal_delay : std_logic := '0';
    signal in_signal_delay_on4x : std_logic := '0';
    signal in_signal_on4x : std_logic := '0';
    signal oct_delay_on4x : std_logic_vector(2 downto 0) := "000";
    -- Given we register to move to 4x domain, we need to delay, so value
    -- phase = 0 in 4x domain correspond to data from phase 0 in original
    -- domain.
    signal phase : unsigned(1 downto 0) := "10";
    signal ddr_a : std_logic := '0';
    signal ddr_b : std_logic := '0';
    signal signal_quad : std_logic := '0';
    signal signal_quad_delay : std_logic := '0';
begin
    process (clk_i) begin
        if rising_edge(clk_i) then
            in_signal_delay <= signal_i;
        end if;
    end process;

    process (clk_4x_i) begin
        if rising_edge(clk_4x_i) then
            in_signal_on4x <= signal_i;
            in_signal_delay_on4x <= in_signal_delay;
            oct_delay_on4x <= oct_delay_i;
            phase <= phase + 1;

            case std_logic_vector(phase) & oct_delay_on4x(2 downto 1) is
                when "0001" =>
                    signal_quad <= in_signal_delay_on4x;
                when "0010" =>
                    signal_quad <= in_signal_delay_on4x;
                when "0110" =>
                    signal_quad <= in_signal_delay_on4x;
                when "0011" =>
                    signal_quad <= in_signal_delay_on4x;
                when "0111" =>
                    signal_quad <= in_signal_delay_on4x;
                when "1011" =>
                    signal_quad <= in_signal_delay_on4x;
                when others =>
                    signal_quad <= in_signal_on4x;
            end case;
        end if;
    end process;

    process (clk_4x_i) begin
        if rising_edge(clk_4x_i) then
            signal_quad_delay <= signal_quad;
            case oct_delay_on4x(0) is
                when '1' =>
                    ddr_a <= signal_quad_delay;
                    ddr_b <= signal_quad;
                when others =>
                    ddr_a <= signal_quad;
                    ddr_b <= signal_quad;
            end case;
        end if;
    end process;

    oddr_inst : ODDRE1 port map (
        Q => signal_o,
        C => clk_4x_i,
        SR => '0',
        D1 => ddr_a,
        D2 => ddr_b
    );
end;
