--Scott Robson <scott.robson@d-tacq.co.uk>
--11:15:37 Thu 21 Dec 2017
--Order of operations to begin data capture on ACQ427 Module
--
--  Set a suitable clock divider.
--    PandA clk_0 is 125 MHz. Max sample rate of ADC is 1 MHz.
--    Set clock A period to 1e-6 and connect to PCAP block CAPTURE port
--
--    Example of clock configuration
--
--    Target sample rate of 1 MHz
--    Internal PandA clock = 125 MHz
--    Set ADC clock divide to 125, 125 / 125 = 1 MHz
--
--  Set FMC Channel Data CAPTURE to "Triggered"
--
--  Set configuration bits in the following order
--    Set MODULE_ENABLE
--    Set ADC_CLKDIV
--    Assert then Deassert ADC_FIFO_RESET
--    Set ADC_ENABLE
--    Set ADC_FIFO_ENABLE
--
--  Data should now be acquiring on the ACQ427. Available to view via the web interface or through standard PCAP acquisition.

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity fmc_adc_start is
    port (clk_i             : in  std_logic;
          reset_i           : in  std_logic;
          MODULE_ENABLE     : out std_logic_vector(31 downto 0);
          ADC_CLK_SELECT    : out std_logic_vector(31 downto 0);
          ADC_CLKDIV        : out std_logic_vector(31 downto 0);
          ADC_FIFO_RESET    : out std_logic_vector(31 downto 0);
          ADC_FIFO_ENABLE   : out std_logic_vector(31 downto 0);
          ADC_RESET         : out std_logic_vector(31 downto 0);
          ADC_ENABLE        : out std_logic_vector(31 downto 0)
);
end fmc_adc_start;


architecture rtl of fmc_adc_start is

constant c_adc_wait_reset : unsigned(3 downto 0) := to_unsigned(10,4);

type t_sm_adc_start is (state_adc_start, state_adc_module_enable, state_adc_clk_select, state_adc_clkdiv, state_adc_fifo_reset_en,
                        state_adc_fifo_reset_dis,  state_adc_reset_dis, state_adc_reset_en, state_adc_fifo_enable, state_adc_enable);

signal sm_adc_start  : t_sm_adc_start;
signal wait_cnt      : unsigned(3 downto 0);
signal enable        : std_logic_vector(9 downto 0) := (others => '0');

begin


ps_start: process(clk_i)
begin
    if rising_edge(clk_i) then
        case sm_adc_start is

            -- Start by reseting everything
            when state_adc_start =>
                wait_cnt <= (others => '0');
                MODULE_ENABLE   <= (others => '0');
                ADC_CLK_SELECT  <= (others => '0');
                ADC_CLKDIV      <= (others => '0');
                ADC_FIFO_RESET  <= (others => '0');
                ADC_FIFO_ENABLE <= (others => '0');
                ADC_RESET       <= (others => '0');
                ADC_ENABLE      <= (others => '0');
                enable <= enable(8 downto 0) & '1';
                if enable(9) = '1' then
                    sm_adc_start <= state_adc_module_enable;
                end if;

            -- Enable the MODULE_ENABLE
            when state_adc_module_enable =>
                MODULE_ENABLE <= std_logic_vector(to_unsigned(1,32));
                sm_adc_start <= state_adc_clk_select;

            -- Select the panda clock
            when state_adc_clk_select =>
                ADC_CLK_SELECT <= (others => '0');
                sm_adc_start <= state_adc_clkdiv;

            -- Target sample rate of 1 MHz
            -- Internal PandA clock = 125 MHz
            -- Set ADC clock divide to 125, 125 / 125 = 1 MHz
            when state_adc_clkdiv =>
                ADC_CLKDIV <= std_logic_vector(to_unsigned(125,32));
                sm_adc_start <= state_adc_fifo_reset_en;

            -- Enable the ADC_FIFO_RESET
            when state_adc_fifo_reset_en =>
                ADC_FIFO_RESET  <= std_logic_vector(to_unsigned(1,32));
                wait_cnt <= wait_cnt +1;
                -- Allow the reset to be high for several clocks
                if (wait_cnt = c_adc_wait_reset) then
                    sm_adc_start <= state_adc_fifo_reset_dis;
                end if;

            -- Disable the ADC_FIFO_RESET
            when state_adc_fifo_reset_dis =>
                wait_cnt <= (others => '0');
                ADC_FIFO_RESET <= (others => '0');
                sm_adc_start <= state_adc_reset_en;

            -- Enable the ADC_RESET
            when state_adc_reset_en =>
                ADC_RESET <= std_logic_vector(to_unsigned(1,32));
                wait_cnt <= wait_cnt +1;
                -- Allow the reset to be high for several clocks
                if (wait_cnt = c_adc_wait_reset) then
                    sm_adc_start <= state_adc_reset_dis;
                end if;

            -- Disable the ADC_RESET
            when state_adc_reset_dis =>
                wait_cnt <= (others => '0');
                ADC_RESET <= (others => '0');
                sm_adc_start <= state_adc_enable;

            -- Enable the ADC_ENABLE
            when state_adc_enable =>
                ADC_ENABLE <= std_logic_vector(to_unsigned(1,32));
                sm_adc_start <= state_adc_fifo_enable;

            -- Enable the ADC_FIFO_ENABLE
            when state_adc_fifo_enable =>
                ADC_FIFO_ENABLE <= std_logic_vector(to_unsigned(1,32));

            when others =>
                sm_adc_start <= state_adc_start;
        end case;
    end if;
end process ps_start;



end rtl;
