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
    STATUS_BITS     : in  std_logic_vector(7 downto 0);
    CRC_BITS        : in  std_logic_vector(7 downto 0);
    -- Physical SSI interface
    ssi_sck_i       : in  std_logic;
    ssi_dat_i       : in  std_logic;
    -- Block outputs
    posn_o          : out std_logic_vector(31 downto 0)
);
end biss_sniffer;

architecture rtl of biss_sniffer is

-- Ticks in terms of internal serial clock period.
constant SYNCPERIOD         : natural := 125 * 5; -- 5usec
type biss_fsm_t is (IDLE, ACK, START, WAIT_ZERO, DATA_RANGE, TIMEOUT);

-- Number of all bits per BiSS Frame
signal DATA_BITS            : unsigned(7 downto 0);
signal LEN                  : natural range 0 to 2**BITS'length-1;
signal reset                : std_logic;

signal data_count           : unsigned(7 downto 0);
signal timeout_count        : unsigned(10 downto 0);
signal biss_fsm             : biss_fsm_t;
signal biss_frame           : std_logic;
signal data_valid           : std_logic;
signal status_valid         : std_logic;
signal crc_valid            : std_logic;

signal serial_clock         : std_logic;
signal serial_clock_prev    : std_logic;
signal serial_clock_rise    : std_logic;
signal serial_data          : std_logic;
signal link_up              : std_logic;
signal shift_in             : std_logic_vector(31 downto 0);
signal shift_in_valid       : std_logic;
signal posn                 : std_logic_vector(31 downto 0);

signal uBITS                : unsigned(7 downto 0);
signal uSTATUS_BITS         : unsigned(7 downto 0);
signal uCRC_BITS            : unsigned(7 downto 0);

begin

-- Internal signal assignments
serial_clock <= ssi_sck_i;
serial_data <= ssi_dat_i;

uBITS        <= unsigned(BITS);
uSTATUS_BITS <= unsigned(STATUS_BITS);
uCRC_BITS    <= unsigned(CRC_BITS);

-- Assign outputs
posn_o <= posn;

-- Frame BITs includes: Start&CDS + Data + Extra(Error/CRC)
DATA_BITS <= uBITS + uSTATUS_BITS + uCRC_BITS;

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

-- Internal reset when link is down
reset <= reset_i or not link_up;

-- Data latch happens on rising edge of incoming clock
serial_clock_rise <= serial_clock and not serial_clock_prev;

--
-- Serial Receive State Machine
--
process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset = '1') then
            biss_fsm <= IDLE;
            biss_frame <= '0';
        else
            -- For rising edge detection
            serial_clock_prev <= serial_clock;

            -- Unidirectional point-to-point BiSS communication
            case biss_fsm is
                when IDLE =>
                    if (serial_clock = '0') then
                        biss_fsm <= ACK;
                    end if;

                when ACK =>
                    if (serial_clock_rise = '1' and serial_data = '0') then
                        biss_fsm <= START;
                    end if;

                when START =>
                    if (serial_clock_rise = '1' and serial_data = '1') then
                        biss_fsm <= WAIT_ZERO;
                    end if;

                when WAIT_ZERO =>
                    if (serial_clock_rise = '1' and serial_data = '0') then
                        biss_fsm <= DATA_RANGE;
                    end if;

                when DATA_RANGE =>
                    if (data_count = DATA_BITS) then
                        biss_fsm <= TIMEOUT;
                    end if;

                when TIMEOUT =>
                    if (timeout_count(timeout_count'left) = '1') then
                        biss_fsm <= IDLE;
                    end if;
            end case;

            -- Set active biss frame flag for link disconnection
            if (biss_fsm = IDLE and serial_clock = '0') then
                biss_frame <= '1';
            elsif (biss_fsm = TIMEOUT) then
                biss_frame <= '0';
            end if;
        end if;
    end if;
end process;

process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset = '1') then
            data_count <= (others => '0');
            timeout_count <= (others => '0');
            data_valid <= '0';
            status_valid <= '0';
            crc_valid <= '0';
        else
            -- Keep track of bits received during SCD frame.
            if (biss_fsm = DATA_RANGE) then
                if (serial_clock_rise = '1') then
                    data_count <= data_count + 1;
                end if;
            else
                data_count <= (others => '0');
            end if;

            -- Keep track of bits received during SCD frame.
            if (biss_fsm = TIMEOUT) then
                timeout_count <= timeout_count + 1;
            else
                timeout_count <= (others => '0');
            end if;

            if (biss_fsm = DATA_RANGE) then
                if (data_count <= uBITS-1) then
                    data_valid <= '1';
                    status_valid <= '0';
                    crc_valid <= '0';
                elsif (data_count <= (uBITS + uSTATUS_BITS-1)) then
                    data_valid <= '0';
                    status_valid <= '1';
                    crc_valid <= '0';
                else
                    data_valid <= '0';
                    status_valid <= '0';
                    crc_valid <= '1';
                end if;
            else
                data_valid <= '0';
                status_valid <= '0';
                crc_valid <= '0';
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
    reset_i         => reset,
    enable_i        => data_valid,
    clock_i         => serial_clock_rise,
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
                posn(I) <= '0';
            else
            -- Sign bit or not depending on BITS parameter.
                if (I < LEN) then
                    posn(I) <= shift_in(I);
                else
                    posn(I) <= shift_in(LEN-1);
                end if;
            end if;
        END LOOP;
    end if;
end process;

end rtl;
