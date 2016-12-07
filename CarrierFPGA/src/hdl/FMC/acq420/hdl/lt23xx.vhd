--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : LTC23XX ADC serial interface which runs at full system clock
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ltc23xx is
port (
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    enable_i            : in  std_logic;

    ADC_BITS            : in  std_logic_vector(7 downto 0);
    ADC_TSMPL           : in  std_logic_vector(7 downto 0);
    ADC_TCONV           : in  std_logic_vector(7 downto 0);

    adc_cnv_o           : out std_logic;
    adc_busy_i          : in  std_logic;
    adc_sck_o           : out std_logic;
    adc_sdo_i           : in  std_logic;

    adc_data_o          : out std_logic_vector(31 downto 0);
    adc_data_val_o      : out std_logic
);
end ltc23xx;

architecture rtl of ltc23xx is

signal ongoing_capture      : std_logic;
signal ongoing_capture_d1   : std_logic;
signal ongoing_capture_d2   : std_logic;
signal ongoing_capture_d3   : std_logic;
signal ongoing_capture_n    : std_logic;
signal adc_cnv              : std_logic;
signal adc_sdo              : std_logic;
signal adc_data             : std_logic_vector(31 downto 0);

signal BITS                 : natural range 0 to 2**ADC_BITS'length-1;
signal TCONV                : natural range 0 to 2**ADC_TCONV'length-1;
signal TSMPL                : natural range 0 to 2**ADC_TSMPL'length-1;
signal adc_counter          : natural range 0 to 255;

begin

BITS <= to_integer(unsigned(ADC_BITS));
TCONV <= to_integer(unsigned(ADC_TCONV));
TSMPL <= to_integer(unsigned(ADC_TSMPL));

adc_cnv_o <= adc_cnv;

--------------------------------------------------------------------------
-- Generate continuous ADC conversion pulse at ADC_TSMPL [clock ticks]
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (enable_i = '0' and ongoing_capture = '0') then
            adc_counter <= 0;
            adc_cnv <= '0';
            ongoing_capture <= '0';
        else
            -- Wrapping rate counter
            if (adc_counter = TSMPL - 1) then
                adc_counter <= 0;
            else
                adc_counter <= adc_counter + 1;
            end if;

            -- Generate CNV and capture signals
            if (adc_counter < 3) then
                adc_cnv <= '1';
            elsif (adc_counter > TCONV and adc_counter <= TCONV + BITS) then
                ongoing_capture <= '1';
            else
                adc_cnv <= '0';
                ongoing_capture <= '0';
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Generate SPI clock at system rate @ 125MHz
--------------------------------------------------------------------------
ongoing_capture_n <= not ongoing_capture;

oddr_inst : ODDR
generic map (
    DDR_CLK_EDGE    => "OPPOSITE_EDGE",
    INIT            => '0',
    SRTYPE          =>  "SYNC"
)
port map (
    Q               => adc_sck_o,
    C               => clk_i,
    CE              => '1',
    D1              => '1',
    D2              => '0',
    R               => ongoing_capture_n,
    S               => '0'
);

--------------------------------------------------------------------------
-- Data capture is aligned with the rising edge of system clock.
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Pipelining is required to relax timing and latch data at the end
        -- of capture
        ongoing_capture_d1 <= ongoing_capture;
        ongoing_capture_d2 <= ongoing_capture_d1;
        ongoing_capture_d3 <= ongoing_capture_d2;

        -- Pack incoming data register first into the IOB
        adc_sdo <= adc_sdo_i;

        if (adc_cnv = '1') then
            adc_data <= (others => '0');
        elsif (ongoing_capture_d2 = '1') then
            adc_data <= adc_data(30 downto 0) & adc_sdo;
        end if;

    end if;
end process;

--------------------------------------------------------------------------
-- Since ADC_BITS is a variable, sign extention has to be performed
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        adc_data_val_o <= '0';

        if (ongoing_capture_d2 = '0' and ongoing_capture_d3 = '1') then
            adc_data_val_o <= '1';

            FOR I IN adc_data'range LOOP
                -- Sign bit or not depending on BITS parameter.
                if (I < BITS) then
                    adc_data_o(I) <= adc_data(I);
                else
                    adc_data_o(I) <= adc_data(BITS-1);
                end if;
            END LOOP;
        end if;
    end if;
end process;

end rtl;

