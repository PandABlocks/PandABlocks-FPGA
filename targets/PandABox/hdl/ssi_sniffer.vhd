--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Serial Interface Synchronous Recevier core.
--                Manages link status, and receives incoming SPI transaction,
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity ssi_sniffer is
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Configuration interface
    BITS            : in  std_logic_vector(7 downto 0);
    DEBOUNCE_EN_i   : in  std_logic;
    DEBOUNCE_TIME_i : in  std_logic_vector(6 downto 0);
    link_up_o       : out std_logic;
    error_o         : out std_logic;
    
    -- Physical SSI interface
    ssi_sck_i       : in  std_logic;
    ssi_dat_i       : in  std_logic;
    -- Block outputs
    posn_o          : out std_logic_vector(31 downto 0)
);
end ssi_sniffer;

architecture rtl of ssi_sniffer is

COMPONENT ila_32x8K

PORT (
	clk : IN STD_LOGIC;
	probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END COMPONENT  ;

-- Ticks in terms of internal serial clock period.
constant SYNCPERIOD         : natural := 125 * 5; -- 5usec

-- Number of all bits per SSI frame
signal uBITS                : unsigned(7 downto 0);
signal intBITS              : natural range 0 to 2**BITS'length-1;

signal reset                : std_logic;
signal serial_data_prev     : std_logic;
signal serial_data_rise     : std_logic;
signal serial_clock         : std_logic;
signal serial_clock_prev    : std_logic;
signal link_up              : std_logic;
signal data                 : std_logic_vector(posn_o'length-1 downto 0);
signal data_valid           : std_logic;
signal ssi_frame            : std_logic;
signal serial_data          : std_logic;
signal serial_clock_fall    : std_logic;
signal serial_clock_rise    : std_logic;
signal shift_counter        : unsigned(7 downto 0);
signal shift_enabled        : std_logic;
signal debounce_en           : std_logic;
signal db_timeout           : std_logic;
signal DEBOUNCE_TIME        : unsigned(6 downto 0);


begin

--------------------------------------------------------------------------
-- Internal signal assignments
--------------------------------------------------------------------------
uBITS <= unsigned(BITS);

-- Internal reset when link is down
reset <= reset_i or not link_up;

debounce_en <= DEBOUNCE_EN_i;
DEBOUNCE_TIME <= unsigned(DEBOUNCE_TIME_i);

serial_clock <= ssi_sck_i;
serial_data <= ssi_dat_i;

process (clk_i)
begin
    if (rising_edge(clk_i)) then
        serial_clock_prev <= serial_clock;
        serial_data_prev <= serial_data;
    end if;
end process;

-- Shift source synchronous data on the Falling egde of clock
serial_clock_fall <=  '0' when (db_timeout='1' and debounce_en='1') else (not serial_clock and serial_clock_prev);
serial_clock_rise <=  '0' when (db_timeout='1' and debounce_en='1') else (serial_clock and not serial_clock_prev);
serial_data_rise <= serial_data and not serial_data_prev;

-- Optional debounce circuit for incoming serial clock, to ensure logic does not respond to reflections
-- on the incoming clock lines.

debouncer : process(clk_i)
    variable db_ctr : unsigned(6 downto 0); -- Allow just over 1 us timeout 
begin
    if rising_edge(clk_i) then
        if (db_timeout = '0') then
            if (serial_clock_rise='1' or serial_clock_fall='1') then
                db_timeout <= '1';
            end if;
        else
            if (db_ctr = DEBOUNCE_TIME) then
                db_timeout <= '0';
                db_ctr := (others => '0');
            else
                db_ctr := db_ctr + 1;
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Detect link if clock is asserted for > 5us.
--------------------------------------------------------------------------
link_detect_inst : entity work.serial_link_detect
generic map (
    SYNCPERIOD          => SYNCPERIOD
)
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    clock_i             => serial_clock,
    active_i            => ssi_frame,
    link_up_o           => link_up
);

--------------------------------------------------------------------------
-- Serial Receive State Machine
--------------------------------------------------------------------------
process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset = '1') then
            shift_counter <= (others => '0');
            ssi_frame <= '0';
            shift_enabled <= '0';
        else
            -- Catch SSI data transmission by monitoring Master clock's
            -- falling edge.
            if (serial_clock_fall = '1' and ssi_frame = '0') then
                ssi_frame <= '1';
            elsif (serial_clock_rise = '1' and shift_counter = uBITS) then
                ssi_frame <= '0';
            end if;

            -- Keep track of bits received within the frame.
            if (ssi_frame = '1') then
                if (serial_clock_rise = '1') then
                    shift_counter <= shift_counter + 1;
                end if;
            else
                shift_counter <= (others => '0');
            end if;

            -- Once enabled, shift data into the register until frame is
            -- finished.
            if (serial_clock_rise = '1' and shift_counter = 0) then
                shift_enabled <= '1';
            elsif (serial_clock_rise = '1' and shift_counter = uBITS) then
                shift_enabled <= '0';
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Shift position data in
--------------------------------------------------------------------------
shifter_in_inst : entity work.shifter_in
generic map (
    DW              => data'length
)
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    enable_i        => shift_enabled,
    clock_i         => serial_clock_fall,
    data_i          => serial_data,
    data_o          => data,
    data_valid_o    => data_valid
);

--------------------------------------------------------------------------
-- Dynamic bit length require sign extention logic
--------------------------------------------------------------------------
intBITS <= to_integer(uBITS);

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (data_valid = '1') then
            FOR I IN data'range LOOP
                -- Sign bit or not depending on BITS parameter.
                if (I < intBITS) then
                    posn_o(I) <= data(I);
                else
                    posn_o(I) <= data(intBITS-1);
                end if;
            END LOOP;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Module status outputs
--   link_down
--   Encoder CRC error
--------------------------------------------------------------------------
link_up_o <= link_up;
error_o <= '0'; -- n/a

ssi_ila : ila_32x8K
PORT MAP (
	clk => clk_i,
	probe0 => data,
    probe1(0) => data_valid,
    probe1(1) => serial_data,
    probe1(2) => serial_clock_fall,
    probe1(10 downto 3) => BITS,
    probe1(11) => link_up,
    probe1(12) => serial_clock,
    probe1(13) => reset,
    probe1(14) => serial_data_prev,
    probe1(15) => serial_clock_prev,
    probe1(16) => ssi_frame,
    probe1(17) => serial_data_rise,
    probe1(18) => serial_clock_rise,
    probe1(19) => shift_enabled,
    probe1(27 downto 20) => std_logic_vector(shift_counter),
    probe1(31 downto 28) => (others => '0')
);

end rtl;
