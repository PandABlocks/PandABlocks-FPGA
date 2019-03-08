--Scott Robson <scott.robson@d-tacq.co.uk>
--14:46:20 Fri 29 Sep 2017
--Order of operations to begin data capture on ACQ430 Module
--
--  Set a suitable clock divider.
--    Final sample rate will depend on source clock, clock divider and ADC Mode.
--    ADC Mode = 0 (High Speed Mode) introduces a sigma-delta divide of 256. This mode should be employed when desired sample rate is > 48 kHz
--    ADC Mode = 1 (High Resolution Mode) introduces a sigma-delta divide of 512. This mode should be employed when desired sampe rate is < 48 kHz
--
--    Example of clock configuration
--
--    Target sample rate of 122 kHz
--    Internal PandA clock = 125 MHz
--    Set clock divide to 4, 125 / 4 = 31.25 MHz
--    Set ADC mode to High Speed, 31.35 / 256 = 122 kHz
--
--    For other sample rates the user will have to design this calculation.
--    Alternatively the external FMC clock can be selected and set to a divide of 1. In this case only the sigma-delta divide will apply.
--
--    It would also be sensible to set the PCAP clock to match the ACQ430 sample rate to avoid oversampling or subsampling.
--
--  Set configuration bits in the following order
--    Set MODULE_ENABLE
--    Set ADC_MODE
--    Set ADC_CLKDIV
--    Assert then Deassert ADC_FIFO_RESET
--    Set ADC_ENABLE
--    Set ADC_FIFO_ENABLE
--
--  Data should now be acquiring on the ACQ430. Available to view via the web interface or through standard PCAP acquisition.


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity fmc_adc430_start is
    port (clk_i         : in  std_logic;
          reset_i       : in  std_logic;
          MODULE_ENABLE : out std_logic_vector(31 downto 0);
          ADC_MODE      : out std_logic_vector(31 downto 0);
          CLK_SELECT    : out std_logic_vector(31 downto 0);
          ADC_CLKDIV    : out std_logic_vector(31 downto 0);
          FIFO_RESET    : out std_logic_vector(31 downto 0);
          FIFO_ENABLE   : out std_logic_vector(31 downto 0);
          ADC_RESET     : out std_logic_vector(31 downto 0);
          ADC_ENABLE    : out std_logic_vector(31 downto 0)
);
end fmc_adc430_start;

architecture rtl of fmc_adc430_start is

constant c_adc_wait_reset : unsigned(4 downto 0) := to_unsigned(10,5);

type t_sm_adc_start is (state_adc_start, state_adc_module_enable, state_adc_mode, state_adc_clk_select, state_adc_clkdiv, state_adc_fifo_en,
                        state_adc_fifo_dis, state_fifo_enable, state_adc_reset_en, state_adc_reset_dis, state_adc_enable);

signal sm_adc_start  : t_sm_adc_start;
signal wait_cnt      : unsigned(4 downto 0);
signal enable        : std_logic_vector(9 downto 0) := (others => '0');


begin


ps_startup: process(clk_i)
begin
    if rising_edge(clk_i) then

        case sm_adc_start is

            -- Wait until the enable gets set
            when state_adc_start =>
                wait_cnt <= (others => '0');
                MODULE_ENABLE <= (others => '0');
                ADC_MODE      <= (others => '0');
                CLK_SELECT    <= (others => '0');
                ADC_CLKDIV    <= (others => '0');
                FIFO_RESET    <= (others => '0');
                FIFO_ENABLE   <= (others => '0');
                ADC_RESET     <= (others => '0');
                ADC_ENABLE    <= (others => '0');
                enable <= enable(8 downto 0) & '1';
                if enable(9) = '1' then
                    sm_adc_start <= state_adc_module_enable;
                end if;

            -- Set the MODULE_ENABLE
            when state_adc_module_enable =>
                MODULE_ENABLE <= std_logic_vector(to_unsigned(1,32));
                sm_adc_start <= state_adc_mode;

            -- ADC Mode = 0 (High Speed Mode) introduces a sigma-delta divide of 256. This mode should be employed when desired sample rate is > 48 kHz
            -- ADC Mode = 1 (High Resolution Mode) introduces a sigma-delta divide of 512. This mode should be employed when desired sampe rate is < 48 kHz
            when state_adc_mode =>
                ADC_MODE <= std_logic_vector(to_unsigned(1,32));
                sm_adc_start <= state_adc_clk_select;

            -- Selects the Panda clock
            -- CLK_SELECT = 0 (Panda Clock)
            -- CLK_SELECT = 1 (External Clock)
            when state_adc_clk_select =>
                CLK_SELECT <= (others => '0');
                sm_adc_start <= state_adc_clkdiv;


            -- Target sample rate of 122 kHz
            -- Internal PandA clock = 125 MHz
            -- Set clock divide to 5, 125 / 5 = 25 MHz
            -- Set ADC mode to High Speed, 25 / 512 = 48.828125 kHz
                ADC_CLKDIV <= std_logic_vector(to_unsigned(5,32));
                sm_adc_start <= state_adc_fifo_en;

            -- Enable the ADC FIFO reset
            when state_adc_fifo_en =>
                FIFO_RESET <= std_logic_vector(to_unsigned(1,32));
                wait_cnt <= wait_cnt +1;
                -- Alow the reset to be high for several clocks
                if (wait_cnt = c_adc_wait_reset) then
                    sm_adc_start <= state_adc_fifo_dis;
                end if;

            -- Disable the ADC FIFO RESETf
            when state_adc_fifo_dis =>
                FIFO_RESET <= (others => '0');
                sm_adc_start <= state_fifo_enable;

            -- Enable the FIFO ENABLE
            when state_fifo_enable =>
                wait_cnt <= (others => '0');
                FIFO_ENABLE <= std_logic_vector(to_unsigned(1,32));
                sm_adc_start <= state_adc_reset_en;

            -- Enable the ADC RESET
            when state_adc_reset_en =>
                wait_cnt <= wait_cnt +1;
                ADC_RESET <= std_logic_vector(to_unsigned(1,32));
                if (wait_cnt = c_adc_wait_reset) then
                    sm_adc_start <= state_adc_reset_dis;
                end if;

            -- Disabled the ADC_RESET
            when state_adc_reset_dis =>
                ADC_RESET <= (others => '0');
                wait_cnt <= wait_cnt +1;
                -- Delay the adc enable otherwise the folowing signals dont get reset
                -- if ADC_ENABLE = '0' or s_SAMPLING_STALLED = '1'  then
                    --      s_SAMPLING_CHANGE_COUNT <= (others => '0');
                    --      s_SAMPLING_GOING_ON <= '0';
                    --      s_SAMPLING_GOING_OFF <= '0';
                    --      s_SAMPLING_ON_DELAYED <= '0';
                    -- In the FMC_FUNC.vhd line 276
                if (wait_cnt = 23) then
                    sm_adc_start <= state_adc_enable;
                end if;

            -- Enable the ADC ENABLE
            when state_adc_enable =>
                ADC_ENABLE <= std_logic_vector(to_unsigned(1,32));
                -- Wait here until enable deasserted

            when others =>
                sm_adc_start <= state_adc_start;
        end case;
    end if;
end process ps_startup;



end rtl;
