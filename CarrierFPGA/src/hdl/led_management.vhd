--------------------------------------------------------------------------------
--  File:       led_management.vhd
--  Desc:       SR Gate Generator.
--
--  Author:     Isa S. Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.slow_defines.all;

entity led_management is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Input and Outputs
    ttlin_i             : in  std_logic_vector(TTLIN_NUM-1 downto 0);
    ttlout_i            : in  std_logic_vector(TTLOUT_NUM-1 downto 0);
    outenc_conn_i       : in  std_logic_vector(ENC_NUM-1 downto 0);
    slow_tlp_o          : out slow_packet
);
end led_management;

architecture rtl of led_management is

-- Total number of LEDs to control
constant LED_COUNT      : natural := TTLIN_NUM + TTLOUT_NUM;

signal check_tick       : std_logic;
signal val              : std_logic_vector(LED_COUNT-1 downto 0);
signal val_prev         : std_logic_vector(LED_COUNT-1 downto 0);
signal oldval           : std_logic_vector(LED_COUNT-1 downto 0);
signal changed          : std_logic_vector(LED_COUNT-1 downto 0);
signal leds             : std_logic_vector(LED_COUNT-1 downto 0);
signal custom           : std_logic_vector(15 downto 0) := (others => '0');

begin

-- Send packets to Slow FPGA every 50ms;
frame_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => reset_i,
    PERIOD      => TO_SVECTOR(6250000, 32),
    pulse_o     => check_tick
);

--
-- Detect change on I/O @check_tick, and toggle led pulses accordingly.
-- LEDs are toggled in sync with the check_tick, not actual I/O transition.
--
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            val <= (others => '0');
            val_prev <= (others => '0');
            oldval <= (others => '0');
            changed <= (others => '0');
            leds <= (others => '0');
        else
            -- Combine all I/O to detect change bits;
            val <= ttlin_i & ttlout_i;
            val_prev <= val;

            -- Check whether a transition occured during 50ms;
            if (check_tick = '1') then
                changed <= val xor val_prev;
            else
                changed <= (val xor val_prev) or changed;
            end if;

            -- Toggle individual ledss;
            FOR I IN 0 TO LED_COUNT-1 LOOP
                if (check_tick = '1') then
                    oldval(I) <= val(I);

                    if (changed(I) = '1') then
                        if (val(I) = oldval(I)) then
                            leds(I) <= not val(I);
                        else
                            leds(I) <= val(I);
                        end if;
                    else
                        leds(I) <= val(I);
                    end if;
                end if;
            END LOOP;
        end if;
    end if;
end process;

--
-- Custom bits currently includes OutEnc disconnect action.
--
custom <= ZEROS(12) & outenc_conn_i;

--
-- Send a packet to Slow FPGA @check_tick rate of 50ms;
--
SLOW_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            slow_tlp_o.strobe <= '0';
            slow_tlp_o.address <= (others => '0');
            slow_tlp_o.data <= (others => '0');
        else
            slow_tlp_o.strobe <= '0';

            if (check_tick = '1') then
                slow_tlp_o.strobe <= '1';
                slow_tlp_o.data <= custom & leds;
                slow_tlp_o.address <= TO_SVECTOR(TTL_LEDS, PAGE_AW);
            end if;
        end if;
    end if;
end process;

end rtl;
