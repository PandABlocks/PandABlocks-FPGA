library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;

entity bit_tester is
    port (
        clk_i : in  std_logic;
        -- Block Input and Outputs
        enable_i : in std_logic;
        trig_i: in std_logic;
        input_i : in std_logic;
        output_o : out std_logic := '0';
        -- Registers
        ERRORS: out std_logic_vector(31 downto 0) := (others => '0')
    );
end;

architecture rtl of bit_tester is
    signal prev_enable : std_logic := '0';
    signal prev_trig : std_logic := '0';
    signal enable_rising : std_logic;
    signal trig_rising : std_logic;
    signal lfsr : std_logic_vector(31 downto 0) := (others => '0');
begin
    enable_rising <= enable_i and not prev_enable;
    trig_rising <= trig_i and not prev_trig;

    latch_prev: process(clk_i)
    begin
        if rising_edge(clk_i) then
            prev_enable <= enable_i;
            prev_trig <= trig_i;
        end if;
    end process;

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if enable_rising then
                ERRORS <= (others => '0');
                lfsr <= x"FEED_CAFE";
            elsif enable_i and trig_rising then
                lfsr <=
                    lfsr(30 downto 0) &
                        (lfsr(31) xor lfsr(21) xor lfsr(1) xor lfsr(0));
                if input_i /= lfsr(0) then
                    ERRORS <= std_logic_vector(unsigned(ERRORS) + 1);
                end if;
            end if;
        end if;
    end process;

    output_o <= lfsr(0);
end;
