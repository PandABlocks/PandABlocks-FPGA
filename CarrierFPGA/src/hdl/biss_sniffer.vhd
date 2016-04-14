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

entity biss_sniffer is
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Configuration interface
    BITS            : in  std_logic_vector(7 downto 0);
    BITS_CRC        : in  std_logic_vector(7 downto 0);
    -- Physical SSI interface
    ssi_sck_i       : in  std_logic;
    ssi_dat_i       : in  std_logic;
    -- Block outputs
    posn_o          : out std_logic_vector(47 downto 0)
);
end biss_sniffer;

architecture rtl of biss_sniffer is

component ila_32x8K
port (
    clk                     : in  std_logic;
    probe0                  : in  std_logic_vector(31 downto 0)
);
end component;

signal probe0               : std_logic_vector(31 downto 0);

-- Ticks in terms of internal serial clock period.
constant SYNCPERIOD         : natural := 125 * 5; -- 5usec

-- Number of all bits per BiSS Frame
signal FRAME_LEN            : unsigned(7 downto 0);
signal LEN                  : natural range 0 to 2**BITS'length-1;

signal serial_data_prev     : std_logic;
signal serial_data_rise     : std_logic;
signal serial_clock         : std_logic;
signal serial_clock_prev    : std_logic;
signal link_up              : std_logic;
signal biss_scd             : std_logic;
signal shift_in             : std_logic_vector(posn_o'length-1 downto 0);
signal shift_in_valid       : std_logic;
signal biss_frame           : std_logic;
signal serial_data          : std_logic;
signal serial_clock_fall    : std_logic;
signal serial_clock_rise    : std_logic;
signal shift_counter        : unsigned(7 downto 0);
signal shift_enabled        : std_logic;

begin

-- Frame BITs includes: Start&CDS + Data + Extra(Error/CRC)
FRAME_LEN <= 2 + unsigned(BITS) + unsigned(BITS_CRC);

--
-- Register inputs and detect rise/fall edges.
--
process (clk_i)
begin
    if (rising_edge(clk_i)) then
        serial_clock <= ssi_sck_i;
        serial_clock_prev <= serial_clock;
        serial_data <= ssi_dat_i;
        serial_data_prev <= serial_data;
    end if;
end process;

-- Shift source synchronous data on the Falling egde of clock
serial_clock_fall <= not serial_clock and serial_clock_prev;
serial_clock_rise <= serial_clock and not serial_clock_prev;
serial_data_rise <= serial_data and not serial_data_prev;

-- Detect link if clock is asserted for > 5us.
link_detect_inst : entity work.ssi_link_detect
generic map (
    SYNCPERIOD          => SYNCPERIOD
)
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    clock_i             => serial_clock,
    active_i            => biss_frame,
    link_up_o           => link_up
);

--
-- Serial Receive State Machine
--
process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset_i = '1' or link_up = '0') then
            shift_counter <= (others => '0');
            biss_frame <= '0';
            biss_scd <= '0';
            shift_enabled <= '0';
        else
            -- BISS Frame: Starts with falling edge of master clock.
            if (serial_clock_fall = '1' and biss_frame = '0') then
                biss_frame <= '1';
            elsif (serial_clock_rise = '1' and shift_counter = FRAME_LEN-1) then
                biss_frame <= '0';
            end if;

            -- BISS Single Cycle Data: Starts with slave's acknowledgement.
            if (biss_frame = '1') then
                if (serial_data_rise = '1' and biss_scd = '0') then
                    biss_scd <= '1';
                end if;
            else
                biss_scd <= '0';
            end if;

            -- Keep track of bits received durin SCD frame.
            if (biss_scd = '1') then
                if (serial_clock_rise = '1') then
                    shift_counter <= shift_counter + 1;
                end if;
            else
                shift_counter <= (others => '0');
            end if;

            -- Encoder data is received within SCD so need a separate valid
            -- flag to shift data into the shift register.
            if (serial_clock_rise = '1' and shift_counter = 1) then
                shift_enabled <= '1';
            elsif (serial_clock_rise = '1' and shift_counter = unsigned(BITS) + 1) then
                shift_enabled <= '0';
            end if;
        end if;
    end if;
end process;

shifter_in_inst : entity work.shifter_in
generic map (
    DW              => shift_in'length
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    enable_i        => shift_enabled,
    clock_i         => serial_clock_fall,
    data_i          => serial_data,
    data_o          => shift_in,
    data_valid_o    => shift_in_valid
);

-- Since BITS is a variable, sign extention for position output
-- has to be performed.

-- Encoder bit length in integer.
LEN <= to_integer(unsigned(BITS));

process(clk_i)
begin
    if rising_edge(clk_i) then
        FOR I IN shift_in'range LOOP
            -- Have to handle 0-bit configuration. Horrible indeed.
            if (LEN = 0) then
                posn_o(I) <= '0';
            else
            -- Sign bit or not depending on BITS parameter.
                if (I < LEN) then
                    posn_o(I) <= shift_in(I);
                else
                    posn_o(I) <= shift_in(LEN-1);
                end if;
            end if;
        END LOOP;
    end if;
end process;

----
---- ILA Instantiation
----
--ila_0_inst : ila_32x8K
--port map (
--    clk                 => clk_i,
--    probe0              => probe0
--);
--
--probe0(0) <= ssi_sck_i;
--probe0(1) <= ssi_dat_i;
--probe0(2) <= biss_frame;
--probe0(3) <= biss_scd;
--probe0(4) <= shift_enabled;
--probe0(12 downto 5) <= std_logic_vector(shift_counter);
--probe0(13) <= serial_clock_rise;
--probe0(14) <= serial_clock_fall;
--probe0(15) <= serial_data;
--probe0(16) <= link_up;
--probe0(17) <= serial_clock;
--probe0(31 downto 18) <= shift_in(13 downto 0);

end rtl;
