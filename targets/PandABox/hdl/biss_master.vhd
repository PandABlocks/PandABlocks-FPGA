
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity biss_master is
port(
    clk_i        : in  std_logic;
    reset_i      : in  std_logic;
    ENCODING     : in  std_logic_vector(0 downto 0);
    BITS         : in  std_logic_vector(7 downto 0);
    link_up_o    : out std_logic;
    health_o     : out  std_logic_vector(31 downto 0);
    CLK_PERIOD   : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD : in  std_logic_vector(31 downto 0);
    biss_sck_o   : out std_logic;
    biss_dat_i   : in  std_logic;
    posn_o       : out std_logic_vector(31 downto 0);
    posn_valid_o : out std_logic
);
end biss_master;

architecture rtl of biss_master is
constant c_LINE_DELAY  : unsigned(12 downto 0) := to_unsigned(5000,13);--40us maximum line delay for ack from slave (biss_dat_i='0') and 1st biss_scl_i='0'
                                                                       --(aka TLineDelay in biss interface protocol description)
constant c_timeout  : unsigned(12 downto 0) := to_unsigned(2500,13);--40us maximum timeout of stop frame 
                                                                    --(aka "BISS TIMEOUT" TBISS_Timeout in biss interface protocol description)
constant c_MAX_START_TIMEOUT  : unsigned(12 downto 0) := to_unsigned(5000,13);--40us maximum timeout wait for start 
                                                                              --(aka "processing time" Tbusy_s in biss interface protocol description)

type t_SM_DATA is (STATE_SYNCH, STATE_ACK, STATE_START, STATE_ZERO, STATE_DATA, STATE_nEnW, STATE_CRC, STATE_TIMEOUT);

signal SM_DATA               : t_SM_DATA;
signal uBITS                 : unsigned(7 downto 0);
signal uSTATUS_BITS          : unsigned(7 downto 0);
signal uCRC_BITS             : unsigned(7 downto 0);
signal uSTART_ZERO           : unsigned(7 downto 0);
signal DATA_BITS             : std_logic_vector(7 downto 0);
signal intBITS               : natural range 0 to 2**BITS'length-1;
signal data_cnt              : unsigned(7 downto 0);

signal start_line_delay_cnt  : std_logic;
signal line_delay_cnt        : unsigned(12 downto 0);
signal timeout_cnt           : unsigned(12 downto 0);
signal start_timeout         : unsigned(12 downto 0);

signal crc_reset             : std_logic := '0';
signal reset_crc             : std_logic;

signal biss_clk_reset        : std_logic;
signal reset_biss_clk        : std_logic;

signal frame_pulse           : std_logic;
signal biss_sck              : std_logic;

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

signal link_up              : std_logic;
signal link_up_crc_nEbit          : std_logic;
signal health_biss_master   : std_logic_vector(31 downto 0);

begin
link_up_o <= link_up and link_up_crc_nEbit;
health_o <= health_biss_master;
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
        if reset_i='1' then
            crc_reset <= '0';
            biss_clk_reset <= '0';
            crc_enable_i <= '0';
            enable_cnt_i <= '0';
            data_enable_i <= '0';
            nEnW_enable_i <= '0';
            start_timeout <= (others=>'0');
            data_cnt <= (others => '0');
            timeout_cnt <= (others => '0');
            biss_clk_reset <= '1';
            link_up<='0';
            line_delay_cnt <= (others=>'0');
            start_line_delay_cnt<='0';
            SM_DATA<=STATE_SYNCH;
        else
            case SM_DATA is
                -- SYNCH STATE
                when STATE_SYNCH =>
                    crc_reset <= '0';
                    biss_clk_reset <= '0';
                    crc_enable_i <= '0';
                    enable_cnt_i <= '0';
                    data_enable_i <= '0';
                    nEnW_enable_i <= '0';
                    start_timeout <= (others=>'0');
                    if start_line_delay_cnt= '1' then
                        line_delay_cnt <= line_delay_cnt + 1;
                    else
                        line_delay_cnt <= (others=>'0');
                    end if;
                    if biss_sck= '0' then
                        start_line_delay_cnt<='1';
                        if biss_dat_i = '0' then
                           data_cnt <= (others => '0');
                           timeout_cnt <= (others => '0');
                           SM_DATA <= STATE_ACK;
                           start_line_delay_cnt<='0';
                        elsif line_delay_cnt>=c_LINE_DELAY then
                           SM_DATA <= STATE_SYNCH;
                           biss_clk_reset <= '1';
                           link_up<='0';
                           start_line_delay_cnt<='0';
                        end if;
                    end if;
                    
            
                -- ACK state
                when STATE_ACK =>
                    line_delay_cnt <= (others=>'0');
                    if (biss_sck_rising_edge = '1') then
                        if (biss_dat_i = '0') then
                            SM_DATA <= STATE_START;
                        else--no ACK return to STATE_SYNCH
                            SM_DATA <= STATE_SYNCH;
                            biss_clk_reset <= '1';
                            start_line_delay_cnt<='0';
                            link_up<='0';
                        end if;
                    end if;
            
                -- START STATE
                when STATE_START =>
                    line_delay_cnt <= (others=>'0');
                    if (start_timeout = c_MAX_START_TIMEOUT) then
                        SM_DATA <= STATE_SYNCH;
                        start_timeout<=(others=>'0');
                        biss_clk_reset <= '1';
                        start_line_delay_cnt<='0';
                        link_up<='0';
                    else 
                        start_timeout<=start_timeout+1;
                        if (biss_sck_rising_edge = '1') and (biss_dat_i = '1') then
                            -- Reset the crc generater
                            crc_reset <= '1';
                            SM_DATA <= STATE_ZERO;
                            start_timeout<=(others=>'0');
                        end if;
                    end if;
            
                -- ZERO STATE
                when STATE_ZERO =>
                    line_delay_cnt <= (others=>'0');
                    if (biss_sck_rising_edge = '1') then
                        if (biss_dat_i = '0') then
                            crc_reset <= '0';
                            enable_cnt_i <= '1';
                            -- Enable data going to the data shifter
                            data_enable_i <= '1';
                            SM_DATA <= STATE_DATA;
                        else--no ZERO return to STATE_SYNCH 
                            SM_DATA <= STATE_SYNCH;
                            biss_clk_reset <= '1';
                            start_line_delay_cnt<='0';
                            link_up<='0';
                        end if;
                    end if;
            
                -- DATA STATE
                when STATE_DATA =>
                    line_delay_cnt <= (others=>'0');
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
                    line_delay_cnt <= (others=>'0');
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
                    line_delay_cnt <= (others=>'0');
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
                    line_delay_cnt <= (others=>'0');
                    enable_cnt_i <= '0';
                    timeout_cnt <= timeout_cnt +1;
                    if (timeout_cnt = c_timeout) then
                        SM_DATA <= STATE_SYNCH;
                        link_up<='1';
                        start_line_delay_cnt<='0';
                    end if;
            end case;
        end if;
    end if;
end process ps_stat;


intBITS <= to_integer(uBITS);

process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i='1' then
            posn_valid_o <= '0';
            link_up_crc_nEbit<='0';
            health_biss_master<=TO_SVECTOR(2,32);--default timeout error
        else
            if link_up = '0' then--timeout error
               posn_valid_o <= '0';
               health_biss_master<=TO_SVECTOR(2,32);
            elsif (crc_valid_o = '1') then--crc calc strobe
               if (crc_o /= crc_calc_o) then--crc error
                  health_biss_master<=TO_SVECTOR(3,32);
                  posn_valid_o <= '0';
                  link_up_crc_nEbit<='0';
               elsif nEnW_o(1) = '0' then--Error received nEnW error bit
                  health_biss_master<=TO_SVECTOR(4,32);
                  posn_valid_o <= '0';
                  link_up_crc_nEbit<='0';
               else--OK
                  posn_valid_o <= '1';
                  FOR I IN data_o'range LOOP
                      -- Sign bit or not depending on BITS parameter.
                      if (I < intBITS) then
                          posn_o(I) <= data_o(I);
                      else
                          posn_o(I) <= data_o(intBITS-1);
                      end if;
                  END LOOP;
                  link_up_crc_nEbit<='1';
                  health_biss_master<=(others=>'0');
               end if;
            else--no crc check update crc_valid_o = '0'
                posn_valid_o <= '0';
            end if;
-- synthesis translate_off
            if (crc_valid_o = '1') then
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
            end if;
-- synthesis translate_on
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

reset_biss_clk <= reset_i or biss_clk_reset;
-- BiSS Clock Gen the same as the ssi Clock Gen except the
-- clock count isn't enabled until the START bit has been received
-- If NO START bit is received after the timeout the clock gen must be reseted
clock_train_inst : entity work.biss_clock_gen
generic map (
    DEAD_PERIOD     => (20000/8)    -- 20us
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_biss_clk,
    N               => DATA_BITS,
    CLK_PERIOD      => CLK_PERIOD,
    start_i         => frame_pulse,
    enable_cnt_i    => enable_cnt_i,
    clock_pulse_o   => biss_sck,
    active_o        => open,
    busy_o          => open
);


calc_enable_i <= (data_enable_i or nEnW_enable_i) and biss_sck_rising_edge;
reset_crc <= reset_i or crc_reset;
-- calculate the actual crc value
biss_crc_inst: entity work.biss_crc
port map(
    clk_i         => clk_i,
    reset_i       => reset_crc,
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
    ENCODING        => ENCODING,
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
    ENCODING        => "0",
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
    ENCODING        => "0",
    enable_i        => crc_enable_i,
    clock_i         => biss_sck_rising_edge,
    data_i          => biss_dat_i,
    data_o          => crc_o,
    data_valid_o    => crc_valid_o
);


end rtl;
