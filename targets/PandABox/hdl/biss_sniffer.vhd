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
    link_up_o       : out std_logic;
    health_o        : out  std_logic_vector(31 downto 0);
    error_o         : out std_logic;
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
signal uBITS                : unsigned(7 downto 0);
signal uSTATUS_BITS         : unsigned(7 downto 0);
signal uCRC_BITS            : unsigned(7 downto 0);
signal DATA_BITS            : unsigned(7 downto 0);
signal intBITS              : natural range 0 to 2**BITS'length-1;

signal reset                : std_logic;
signal data_count           : unsigned(7 downto 0);
signal biss_fsm             : biss_fsm_t;
signal biss_frame           : std_logic;
signal data_valid           : std_logic;
signal nError_valid         : std_logic;
signal crc_valid            : std_logic;
signal data                 : std_logic_vector(31 downto 0);
signal nError               : std_logic_vector(1 downto 0);
signal crc                  : std_logic_vector(5 downto 0);
signal crc_strobe             : std_logic;

signal serial_clock         : std_logic;
signal serial_clock_prev    : std_logic;
signal serial_clock_rise    : std_logic;
signal serial_data          : std_logic;
signal serial_data_prev     : std_logic;
signal serial_data_rise     : std_logic;
signal link_up              : std_logic;

signal crc_reset            : std_logic;
signal crc_bitstrb          : std_logic;
signal crc_calc             : std_logic_vector(5 downto 0);
signal health_biss_sniffer  : std_logic_vector(31 downto 0);

begin

-- Per BiSS-C Protocol BP3
uBITS        <= unsigned(BITS);
uSTATUS_BITS <= X"02";  -- nE(0) and nW(0)
uCRC_BITS    <= X"06";  -- 6-bits for data

-- Data range = Data + nE + nW + CRC
DATA_BITS <= uBITS + uSTATUS_BITS + uCRC_BITS;

--------------------------------------------------------------------------
-- Internal signal assignments
--------------------------------------------------------------------------
serial_clock <= ssi_sck_i;
serial_data <= ssi_dat_i;

process (clk_i)
begin
    if (rising_edge(clk_i)) then
        serial_clock_prev <= serial_clock;
        serial_data_prev <= serial_data;
    end if;
end process;

-- Internal reset when link is down
reset <= reset_i or not link_up;

-- Data latch happens on rising edge of incoming clock
serial_clock_rise <= serial_clock and not serial_clock_prev;
serial_data_rise <= serial_data and not serial_data_prev;

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
    active_i            => biss_frame,
    link_up_o           => link_up
);

--------------------------------------------------------------------------
-- Biss-C profile BP3 receive State Machine
--------------------------------------------------------------------------
process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset = '1') then
            biss_fsm <= IDLE;
            biss_frame <= '0';
        else
            -- Unidirectional point-to-point BiSS communication
            case biss_fsm is
                when IDLE =>
                    if (serial_clock = '0' and serial_data = '0') then
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
                    if (serial_data_rise = '1') then
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

--------------------------------------------------------------------------
-- Generate valid flags for Data, Status and CRC parts of the
-- incoming serial data stream
--------------------------------------------------------------------------
process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset = '1') then
            data_count <= (others => '0');
            data_valid <= '0';
            nError_valid <= '0';
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

            -- Data range includes all serial data
            if (biss_fsm = DATA_RANGE) then
                if (data_count <= uBITS-1) then
                    data_valid <= '1';
                    nError_valid <= '0';
                    crc_valid <= '0';
                elsif (data_count <= (uBITS + uSTATUS_BITS-1)) then
                    data_valid <= '0';
                    nError_valid <= '1';
                    crc_valid <= '0';
                else
                    data_valid <= '0';
                    nError_valid <= '0';
                    crc_valid <= '1';
                end if;
            else
                data_valid <= '0';
                nError_valid <= '0';
                crc_valid <= '0';
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Shift position data in
--------------------------------------------------------------------------
data_in_inst : entity work.shifter_in
generic map (
    DW              => data'length
)
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    enable_i        => data_valid,
    clock_i         => serial_clock_rise,
    data_i          => serial_data,
    data_o          => data,
    data_valid_o    => open
);

-- Shift status data (nE and nW) in
nError_in_inst : entity work.shifter_in
generic map (
    DW              => nError'length
)
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    enable_i        => nError_valid,
    clock_i         => serial_clock_rise,
    data_i          => serial_data,
    data_o          => nError,
    data_valid_o    => open
);

-- Shift 6-bit CRC data in
crc_in_inst : entity work.shifter_in
generic map (
    DW              => crc'length
)
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    enable_i        => crc_valid,
    clock_i         => serial_clock_rise,
    data_i          => serial_data,
    data_o          => crc,
    data_valid_o    => crc_strobe
);

-- Calculate 6-bit CRC from incoming data + status bits
crc_reset <= '1' when (biss_fsm = START) else '0';
crc_bitstrb <= serial_clock_rise and (data_valid or nError_valid);

biss_crc_inst : entity work.biss_crc
port map (
    clk_i           => clk_i,
    reset_i         => crc_reset,

    bitval_i        => serial_data,
    bitstrb_i       => crc_bitstrb,
    crc_o           => crc_calc
);

--------------------------------------------------------------------------
-- Dynamic bit length require sign extention logic
-- Latch position data when Error and CRC valid
--------------------------------------------------------------------------
intBITS <= to_integer(uBITS);

process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i='1' then
            health_biss_sniffer<=TO_SVECTOR(2,32);--default timeout error
        else
            if link_up = '0' then--timeout error
               health_biss_sniffer<=TO_SVECTOR(2,32);
            elsif (crc_strobe = '1') then--crc calc strobe
               if (crc /= crc_calc) then--crc error
                  health_biss_sniffer<=TO_SVECTOR(3,32);
               elsif nError(1) = '0' then--Error received nEnW error bit
                  health_biss_sniffer<=TO_SVECTOR(4,32);
               else--OK
                  FOR I IN data'range LOOP
                      -- Sign bit or not depending on BITS parameter.
                      if (I < intBITS) then
                          posn_o(I) <= data(I);
                      else
                          posn_o(I) <= data(intBITS-1);
                      end if;
                  END LOOP;
                  health_biss_sniffer<=(others=>'0');
               end if;
           end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Module status outputs
--   link_down
--   Encoder CRC error
--------------------------------------------------------------------------
link_up_o <= link_up;
health_o <= health_biss_sniffer;
error_o <= crc_strobe when (crc /= crc_calc or nError(1) = '0') else '0';

end rtl;
