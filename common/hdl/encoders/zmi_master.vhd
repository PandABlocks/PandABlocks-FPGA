-- Read Zygo ZMI serial interface as encoder input
--
-- The ZMI 4100 sends 50 bit frames (32 bit position words, LSB first,
-- 40 Mbit/s): start bit, 3 x Hamming (16,11) SECDED protected blocks
-- containing Pos<31..0> and Zmi_err, stop bit (see zmi_hamming.vhd).
-- Single bit errors per block are corrected, double bit errors are
-- detected and the frame is discarded.
--
-- posn_status_o:
--   bit 0      : last frame ok (checksum ok or corrected), cleared when
--                no frame has been received for 1 ms (link timeout)
--   bit 1      : last frame contained corrected single bit error(s)
--   bit 2      : last frame had an uncorrectable checksum error
--   bit 3      : last frame had a stop bit error
--   bit 4      : Zmi_err flag of last frame
--   bits 7..5  : uncorrectable error per block of last frame
--   bits 15..8 : count of frames with corrected errors (wraps)
--   bits 31..16: count of frames with uncorrectable errors (wraps)
--
-- On a link timeout bits 7..0 and posn_valid_o are cleared, posn_o holds the
-- last good position.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity zmi_master is
port (
    -- Global system and reset interface
    clk_i           : in  std_logic;
    clk_200_i       : in  std_logic;
    reset_i         : in  std_logic;
    -- Block Inputs and Outputs
    zmi_sck_o       : out std_logic;
    zmi_dat_i       : in  std_logic;
    posn_o          : out std_logic_vector(31 downto 0);
    posn_valid_o    : out std_logic;
    posn_status_o   : out std_logic_vector(31 downto 0)
);
end zmi_master;

architecture rtl of zmi_master is

-- Link timeout: 1 ms at 200 MHz
constant TIMEOUT_CYCLES     : natural := 200000;

signal reset_200            : std_logic_vector(1 downto 0) := (others => '1');
signal rx_data_ok           : std_logic;
signal rx_frame_err         : std_logic;
signal rx_frame_done        : std_logic;
signal rx_data_in           : std_logic_vector(47 downto 0);

-- Hamming check outputs (clk_200 domain)
signal chk_posn             : std_logic_vector(31 downto 0);
signal chk_zmi_err          : std_logic;
signal chk_valid            : std_logic;
signal chk_corrected        : std_logic;
signal chk_uncorrectable    : std_logic;
signal chk_block_err        : std_logic_vector(2 downto 0);
signal frame_err_dly        : std_logic_vector(1 downto 0);

-- Result registers (clk_200 domain), held stable between frames
signal posn_latch           : std_logic_vector(31 downto 0);
signal posn_valid_latch     : std_logic;
signal status_latch         : std_logic_vector(31 downto 0);
signal corrected_cnt        : unsigned(7 downto 0);
signal uncorrectable_cnt    : unsigned(15 downto 0);
signal update_toggle        : std_logic := '0';
signal timeout_cnt          : natural range 0 to TIMEOUT_CYCLES;

-- Clock domain crossing (clk_i domain)
signal update_toggle_sync   : std_logic_vector(2 downto 0) := (others => '0');

attribute ASYNC_REG : string;
attribute ASYNC_REG of reset_200 : signal is "TRUE";
attribute ASYNC_REG of update_toggle_sync : signal is "TRUE";

begin

-- The ZMI is self-timed (SCLK), no clock is sent to it
zmi_sck_o <= '0';

-- Synchronise reset into clk_200 domain
process(clk_200_i)
begin
    if rising_edge(clk_200_i) then
        reset_200 <= reset_200(0) & reset_i;
    end if;
end process;

zmi_uart_rx : entity work.UART_RX
generic map (
        CLK_DIV_VAL => 5
    )
port map (
        CLK          => clk_200_i, -- system clock
        RST          => reset_200(1), -- high active synchronous reset
        -- UART INTERFACE
        UART_CLK_EN  => '1',        -- oversampling UART clock enable
        UART_RXD     => zmi_dat_i,  -- serial receive data
        -- USER DATA OUTPUT INTERFACE
        DOUT         => rx_data_in,   -- frame bits 1..48
        DOUT_VLD     => rx_data_ok,   -- frame received, stop bit ok
        FRAME_ERROR  => rx_frame_err  -- frame received, stop bit invalid
    );

-- Every received frame is checked, the Hamming code decides about validity
rx_frame_done <= rx_data_ok or rx_frame_err;

zmi_hamming_inst : entity work.zmi_hamming
port map (
    clk_i           => clk_200_i,
    reset_i         => reset_200(1),
    data_i          => rx_data_in,
    valid_i         => rx_frame_done,
    posn_o          => chk_posn,
    zmi_err_o       => chk_zmi_err,
    valid_o         => chk_valid,
    corrected_o     => chk_corrected,
    uncorrectable_o => chk_uncorrectable,
    block_err_o     => chk_block_err
);

-- Evaluate check result
zmi_result : process(clk_200_i)
begin
    if rising_edge(clk_200_i) then
        -- Align stop bit error with the 2 cycle latency of zmi_hamming
        frame_err_dly <= frame_err_dly(0) & rx_frame_err;

        if reset_200(1) = '1' then
            posn_latch <= (others => '0');
            posn_valid_latch <= '0';
            status_latch <= (others => '0');
            corrected_cnt <= (others => '0');
            uncorrectable_cnt <= (others => '0');
            timeout_cnt <= 0;
        elsif chk_valid = '1' then
            timeout_cnt <= 0;

            if chk_uncorrectable = '0' then
                -- Keep last good position on checksum error
                posn_latch <= chk_posn;
                posn_valid_latch <= not chk_zmi_err;
            else
                posn_valid_latch <= '0';
            end if;

            if chk_corrected = '1' then
                corrected_cnt <= corrected_cnt + 1;
            end if;
            if chk_uncorrectable = '1' then
                uncorrectable_cnt <= uncorrectable_cnt + 1;
            end if;

            status_latch(0) <= not chk_uncorrectable;
            status_latch(1) <= chk_corrected;
            status_latch(2) <= chk_uncorrectable;
            status_latch(3) <= frame_err_dly(1);
            status_latch(4) <= chk_zmi_err;
            status_latch(7 downto 5) <= chk_block_err;
        elsif timeout_cnt = TIMEOUT_CYCLES - 1 then
            -- No frame for 1 ms: link lost, keep last position
            timeout_cnt <= TIMEOUT_CYCLES;
            posn_valid_latch <= '0';
            status_latch(7 downto 0) <= (others => '0');
        elsif timeout_cnt /= TIMEOUT_CYCLES then
            timeout_cnt <= timeout_cnt + 1;
        end if;

        status_latch(15 downto 8) <= std_logic_vector(corrected_cnt);
        status_latch(31 downto 16) <= std_logic_vector(uncorrectable_cnt);

        -- Signal new result (frame or timeout) to clk_i domain
        if chk_valid = '1' or
           (reset_200(1) = '0' and timeout_cnt = TIMEOUT_CYCLES - 1) then
            update_toggle <= not update_toggle;
        end if;
    end if;
end process;

-- Transfer to clk_i domain: the latches are stable for a whole frame
-- (>= 1.3 us), so they are sampled only after the synchronised toggle.
zmi_cdc : process(clk_i)
begin
    if rising_edge(clk_i) then
        update_toggle_sync <= update_toggle_sync(1 downto 0) & update_toggle;

        if reset_i = '1' then
            posn_o <= (others => '0');
            posn_valid_o <= '0';
            posn_status_o <= (others => '0');
        elsif update_toggle_sync(2) /= update_toggle_sync(1) then
            posn_o <= posn_latch;
            posn_valid_o <= posn_valid_latch;
            posn_status_o <= status_latch;
        end if;
    end if;
end process;

end rtl;
