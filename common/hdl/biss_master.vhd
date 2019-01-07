
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity biss_master is
port(
    clk_i        : in  std_logic;
    reset_i      : in  std_logic;
    BITS         : in  std_logic_vector(7 downto 0);
    CLK_PERIOD   : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD : in  std_logic_vector(31 downto 0);
    biss_sck_o   : out std_logic;
    biss_dat_i   : in  std_logic;
    posn_o       : out std_logic_vector(31 downto 0);
    posn_valid_o : out std_logic
);
end biss_master;

architecture rtl of biss_master is

constant c_timeout  : unsigned(11 downto 0) := to_unsigned(2500,12);

type t_SM_DATA is (STATE_SYNCH, STATE_ACK, STATE_START, STATE_ZERO, STATE_DATA, STATE_nEnW, STATE_CRC, STATE_TIMEOUT);

signal SM_DATA               : t_SM_DATA;
signal uBITS                 : unsigned(7 downto 0);
signal uSTATUS_BITS          : unsigned(7 downto 0);
signal uCRC_BITS             : unsigned(7 downto 0);
signal uSTART_ZERO           : unsigned(7 downto 0);
signal DATA_BITS             : std_logic_vector(7 downto 0);
signal intBITS               : natural range 0 to 2**BITS'length-1;
signal data_cnt              : unsigned(7 downto 0);
signal timeout_cnt           : unsigned(11 downto 0);
signal crc_reset             : std_logic := '0';
signal reset                 : std_logic;

signal frame_pulse           : std_logic;
signal biss_sck              : std_logic;
signal shift_enable          : std_logic;

signal biss_sck_prev         : std_logic;
signal biss_sck_rising_edge  : std_logic;
signal biss_sck_falling_edge : std_logic;

signal data_enable_i         : std_logic;
signal nEnW_enable_i         : std_logic;
signal crc_enable_i          : std_logic;
signal enable_cnt_i          : std_logic;
signal calc_enable_i         : std_logic;

signal data_o                : std_logic_vector(31 downto 0);
signal nEnW_o                : std_logic_vector(1 downto 0);
signal crc_o                 : std_logic_vector(5 downto 0);
signal crc_calc_o            : std_logic_vector(5 downto 0);

signal data_valid_o          : std_logic;
signal crc_valid_o           : std_logic;


begin

biss_sck_o <= biss_sck;

uSTART_ZERO  <= X"01";
-- Data
uBITS        <= unsigned(BITS);
-- nEnW
uSTATUS_BITS <= X"02";
-- CRC
uCRC_BITS    <= X"06";
-- Total
DATA_BITS <= std_logic_vector(uSTART_ZERO + uBITS-1 + uSTATUS_BITS + uCRC_BITS);


biss_sck_rising_edge <= not biss_sck_prev and biss_sck;
biss_sck_falling_edge <= biss_sck_prev and not biss_sck;

ps_prev: process(clk_i)
begin
    if rising_edge(clk_i) then
        biss_sck_prev <= biss_sck;
    end if;
end process ps_prev;


--MA ````````\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/```````````````````````

--SL                 | ACK |START| '0' |     DATA 1 to 55      |    nEnW   |                   CRC             | TIMEOUT   |
--SL`````````````````\_____/`````\_____X_____X_____X_____X_____/```````````\_____X_____X_____X_____X_____X_____X___________/````````````


ps_stat: process(clk_i)
begin
    if rising_edge(clk_i) then
        case SM_DATA is

            -- SYNCH STATE
            when STATE_SYNCH =>
                crc_reset <= '0';
                crc_enable_i <= '0';
                enable_cnt_i <= '0';
                data_enable_i <= '0';
                nEnW_enable_i <= '0';
                if (biss_sck = '0' and biss_dat_i = '0') then
                    data_cnt <= (others => '0');
                    timeout_cnt <= (others => '0');
                    if (biss_sck = '0' and biss_dat_i = '0') then
                        SM_DATA <= STATE_ACK;
                    end if;
                end if;

            -- ACK state
            when STATE_ACK =>
                if (biss_sck_rising_edge = '1' and biss_dat_i = '0') then
                    SM_DATA <= STATE_START;
                end if;

            -- START STATE
            when STATE_START =>
                if (biss_sck_rising_edge = '1' and biss_dat_i = '1') then
                    enable_cnt_i <= '1';
                    -- Reset the crc generater
                    crc_reset <= '1';
                    SM_DATA <= STATE_ZERO;
                end if;

            -- ZERO STATE
            when STATE_ZERO =>
                if (biss_sck_rising_edge = '1' and biss_dat_i = '0') then
                    crc_reset <= '0';
                    -- Enable data going to the data shifter
                    data_enable_i <= '1';
                    SM_DATA <= STATE_DATA;
                end if;

            -- DATA STATE
            when STATE_DATA =>
                if (biss_sck_rising_edge = '1') then
                    data_cnt <= data_cnt +1;
                    -- Disable the data going to the data shifter
                    -- Enable the data going to the nEnW shifter
                    if (data_cnt = uBITS-1) then
                        data_enable_i <= '0';
                        nEnW_enable_i <= '1';
                    end if;
                    -- DATA finished
                    if (data_cnt = uBITS) then
                        SM_DATA <= STATE_nEnW;
                    end if;
                end if;

            -- nEnW STATE
            when STATE_nEnW =>
                if (biss_sck_rising_edge = '1') then
                    data_cnt <= data_cnt +1;
                    -- Disbale the data going to the nEnW shifter
                    -- Enable the data going to the CRC shifter
                    if (data_cnt = (uBITS + USTATUS_BITS-1)) then
                        nEnW_enable_i <= '0';
                        crc_enable_i <= '1';
                    end if;
                    -- nEnW finished
                    if (data_cnt = (uBITS + uSTATUS_BITS)) then
                        SM_DATA <= STATE_CRC;
                    end if;
                end if;

            -- CRC STATE
            when STATE_CRC =>
                if (biss_sck_rising_edge = '1') then
                    data_cnt <= data_cnt +1;
                    if (data_cnt = (uBITS + uSTATUS_BITS + uCRC_BITS)-1) then
                        crc_enable_i <= '0';
                        SM_DATA <= STATE_TIMEOUT;
                    end if;
                end if;

            -- TIMEOUT 12.5us minimum
            --         40us   maximum
            when STATE_TIMEOUT =>
                enable_cnt_i <= '0';
                timeout_cnt <= timeout_cnt +1;
                if (timeout_cnt = c_timeout) then
                    SM_DATA <= STATE_SYNCH;
                end if;

            when others =>
                SM_DATA <= STATE_SYNCH;

        end case;
    end if;
end process ps_stat;


intBITS <= to_integer(uBITS);

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (crc_valid_o = '1') then
-- synthesis translate_off
            if (crc_o /= crc_calc_o) then
                report " CRC received is " & integer'image(to_integer(unsigned(crc_o))) & " CRC calculated is " & integer'image(to_integer(unsigned(crc_calc_o))) severity error;
            end if;
            -- Warning received
            if (nEnW_o = "10") then
                report " Warning received nEnW = 10 " severity note;
            -- Error received
            elsif (nEnW_o = "01") then
                report " Error received nEnW = 01 " severity note;
            -- Warning and Error received
            elsif (nEnW_o = "00") then
                report " Error and Warning received nEnW = 00 " severity note;
            end if;
-- synthesis translate_on
            posn_valid_o <= '1';
            if (nEnW_o(1) = '1' and crc_o = crc_calc_o) then
            FOR I IN data_o'range LOOP
                -- Sign bit or not depending on BITS parameter.
                if (I < intBITS) then
                    posn_o(I) <= data_o(I);
                else
                    posn_o(I) <= data_o(intBITS-1);
                end if;
            END LOOP;
            end if;
        else
            posn_valid_o <= '0';
        end if;
    end if;
end process;


-- Generate Internal BiSS Frame from system clock
-- BiSS FRAME = SYNCH1, SYNCH2, ACK, START, ZERO(CDS), DATA, nEnW and CRC
frame_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => reset_i,
    PERIOD      => FRAME_PERIOD,
    pulse_o     => frame_pulse
);


-- BiSS Clock Gen the same as the biss Clock Gen except the
-- clock count isn't enabled until the START bit has been received
clock_train_inst : entity work.biss_clock_gen
generic map (
    DEAD_PERIOD     => (20000/8)    -- 20us
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    N               => DATA_BITS,
    CLK_PERIOD      => CLK_PERIOD,
    start_i         => frame_pulse,
    enable_cnt_i    => enable_cnt_i,
    clock_pulse_o   => biss_sck,
    active_o        => shift_enable,
    busy_o          => open
);


calc_enable_i <= (data_enable_i or nEnW_enable_i) and biss_sck_rising_edge;
reset <= reset_i or crc_reset;
-- calculate the actual crc value
biss_crc_inst: entity work.biss_crc
port map(
    clk_i         => clk_i,
    reset_i       => reset,
    bitval_i      => biss_dat_i,
    bitstrb_i     => calc_enable_i,
    crc_o         => crc_calc_o
);


-- Capture the data value
shifter_data_in_inst : entity work.shifter_in
generic map (
    DW              => (data_o'length)
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    enable_i        => data_enable_i,
    clock_i         => biss_sck_rising_edge,
    data_i          => biss_dat_i,
    data_o          => data_o,
    data_valid_o    => data_valid_o
);


-- Capture the nEnW value
shifter_nEnW_in_inst : entity work.shifter_in
generic map (
    DW              => (nEnW_o'length)
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    enable_i        => nEnW_enable_i,
    clock_i         => biss_sck_rising_edge,
    data_i          => biss_dat_i,
    data_o          => nEnW_o,
    data_valid_o    => open
);


-- Capture the CRC value
shifter_CRC_in_inst : entity work.shifter_in
generic map (
    DW              => (crc_o'length)
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    enable_i        => crc_enable_i,
    clock_i         => biss_sck_rising_edge,
    data_i          => biss_dat_i,
    data_o          => crc_o,
    data_valid_o    => crc_valid_o
);


end rtl;
