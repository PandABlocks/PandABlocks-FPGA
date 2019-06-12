library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.support.all;

entity biss_slave is
port (
    -- Global system and reset interface.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Configuration interface.
    BITS                : in  std_logic_vector(7 downto 0);
    health_o            : out std_logic_vector(31 downto 0);
    -- Block Input and Outputs.
    posn_i              : in  std_logic_vector(31 downto 0);
    biss_sck_i          : in  std_logic;
    biss_dat_o          : out std_logic
);
end entity;


architecture rtl of biss_slave is

constant c_nEnW_size     : unsigned(7 downto 0)  := to_unsigned(2,8);
constant c_CRC_size      : unsigned(7 downto 0)  := to_unsigned(6,8);
constant c_timeout       : unsigned(11 downto 0) := to_unsigned(2500,12);
constant c_MAX_TIMEOUT   : unsigned(12 downto 0) := to_unsigned(5000,13);--40us maximum timeout wait 
                                                                        --(aka "processing time" Tbusy_s in biss interface protocol description)
constant c_nEnW          : std_logic_vector(1 downto 0) := "11";

type t_SM_DATA is (STATE_SYNCH, STATE_ACK, STATE_START, STATE_ZERO, STATE_DATA, STATE_nEnW, STATE_CRC, STATE_STOP);

signal SM_DATA              : t_SM_DATA;
signal data_enable          : std_logic;
signal nEnW_enable          : std_logic;
signal biss_sck_prev        : std_logic;
signal biss_sck_rising_edge : std_logic;
signal calc_enable_i        : std_logic;
signal reset                : std_logic;
signal crc_reset            : std_logic := '1';
signal biss_dat             : std_logic := '1';
signal crc_o                : std_logic_vector(5 downto 0);
signal data_cnt             : unsigned(7 downto 0);
signal timeout_cnt          : unsigned(11 downto 0);
signal sck_timeout_cnt      : unsigned(12 downto 0);
signal health_biss_slave   : std_logic_vector(31 downto 0);

begin

biss_dat_o <= biss_dat;
health_o <= health_biss_slave;

ps_prev: process(clk_i)
begin
    if rising_edge(clk_i) then
        biss_sck_prev <= biss_sck_i;
    end if;
end process ps_prev;


biss_sck_rising_edge <= not biss_sck_prev and biss_sck_i;


ps_timeout: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Reset timeout count
        if (SM_DATA = STATE_SYNCH) then
            timeout_cnt <= (others => '0');
        -- Start timeout count
        elsif (SM_DATA = STATE_STOP) then
            -- Stop timeout count once terminal count reached
            if (timeout_cnt /= c_timeout) then
                timeout_cnt <= timeout_cnt +1;
            end if;
        end if;
    end if;
end process ps_timeout;



--MA ````````\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/```````````````````````

--SL                 | ACK |START| '0' |     DATA 1 to 55      |    nEnW   |                   CRC             | TIMEOUT   |
--SL`````````````````\_____/`````\_____X_____X_____X_____X_____/```````````\_____X_____X_____X_____X_____X_____X___________/````````````


ps_case: process (clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i='1' then
            biss_dat <= '1';
            data_enable <= '0';
            nEnW_enable <= '0';
            crc_reset <= '1';
                -- BITS + c_nEnW(2) + c_CRC(6)
            data_cnt <= unsigned(BITS) + c_nEnW_size + c_CRC_size;
            SM_DATA <= STATE_SYNCH;
            sck_timeout_cnt<=c_MAX_TIMEOUT;
            health_biss_slave<=TO_SVECTOR(1,32);--default error 
        else
           case SM_DATA is
		   
               -- SYNCH STATE
               when STATE_SYNCH =>
                   biss_dat <= '1';
                   data_enable <= '0';
                   nEnW_enable <= '0';
                   sck_timeout_cnt<=sck_timeout_cnt-1;
                   if (biss_sck_rising_edge = '1') then
                       crc_reset <= '1';
                       -- BITS + c_nEnW(2) + c_CRC(6)
                       data_cnt <= unsigned(BITS) + c_nEnW_size + c_CRC_size;
                       biss_dat <= '1';
                       SM_DATA <= STATE_ACK;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                   elsif sck_timeout_cnt=0 then
                       biss_dat <= '1';
                       crc_reset <= '1';
                       data_enable <= '0';
                       nEnW_enable <= '0';
                       data_cnt <= unsigned(BITS) + c_nEnW_size + c_CRC_size;
                       SM_DATA <= STATE_SYNCH;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                       health_biss_slave<=TO_SVECTOR(1,32);--biss_sck_rising_edge receive timeout error
                   end if;
		   
               -- ACK STATE
               when STATE_ACK =>
                   -- ACK = 0
                   sck_timeout_cnt<=sck_timeout_cnt-1;
                   if (biss_sck_rising_edge = '1') then
                       crc_reset <= '0';
                       biss_dat <= '0';
                       SM_DATA <= STATE_START;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                   elsif sck_timeout_cnt=0 then
                       biss_dat <= '1';
                       crc_reset <= '1';
                       data_enable <= '0';
                       nEnW_enable <= '0';
                       data_cnt <= unsigned(BITS) + c_nEnW_size + c_CRC_size;
                       SM_DATA <= STATE_SYNCH;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                       health_biss_slave<=TO_SVECTOR(1,32);--biss_sck_rising_edge receive timeout error
                   end if;
               -- START STATE
               when STATE_START =>
                   -- START = 1
                   sck_timeout_cnt<=sck_timeout_cnt-1;
                   if (biss_sck_rising_edge = '1') then
                       biss_dat <= '1';
                       SM_DATA <= STATE_ZERO;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                   elsif sck_timeout_cnt=0 then
                       biss_dat <= '1';
                       crc_reset <= '1';
                       data_enable <= '0';
                       nEnW_enable <= '0';
                       data_cnt <= unsigned(BITS) + c_nEnW_size + c_CRC_size;
                       SM_DATA <= STATE_SYNCH;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                       health_biss_slave<=TO_SVECTOR(1,32);--biss_sck_rising_edge receive timeout error
                   end if;
		   
               -- ZERO STATE
               when STATE_ZERO =>
                   -- ZERO = 0
                   sck_timeout_cnt<=sck_timeout_cnt-1;
                   if (biss_sck_rising_edge = '1') then
                       biss_dat <= '0';
                       data_enable <= '1';
                       SM_DATA <= STATE_DATA;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                   elsif sck_timeout_cnt=0 then
                       biss_dat <= '1';
                       crc_reset <= '1';
                       data_enable <= '0';
                       nEnW_enable <= '0';
                       data_cnt <= unsigned(BITS) + c_nEnW_size + c_CRC_size;
                       SM_DATA <= STATE_SYNCH;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                       health_biss_slave<=TO_SVECTOR(1,32);--biss_sck_rising_edge receive timeout error
                   end if;
		   
               -- DATA STATE
               when STATE_DATA =>
                   -- Transmit data
                   sck_timeout_cnt<=sck_timeout_cnt-1;
                   if (biss_sck_rising_edge = '1') then
                       data_cnt <= data_cnt -1;
                       biss_dat <= posn_i(to_integer(data_cnt-9));
                       if (data_cnt = 9) then
                           data_enable <= '0';
                           nEnW_enable <= '1';
                           SM_DATA <= STATE_nEnW;
                       end if;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                   elsif sck_timeout_cnt=0 then
                       biss_dat <= '1';
                       crc_reset <= '1';
                       data_enable <= '0';
                       nEnW_enable <= '0';
                       data_cnt <= unsigned(BITS) + c_nEnW_size + c_CRC_size;
                       SM_DATA <= STATE_SYNCH;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                       health_biss_slave<=TO_SVECTOR(1,32);--biss_sck_rising_edge receive timeout error
                   end if;
		   
               -- nE(error flag) nW(warning flag) STATE
               when STATE_nEnW =>
                   -- Transmit the error and warning bits
                   sck_timeout_cnt<=sck_timeout_cnt-1;
                   if (biss_sck_rising_edge = '1') then
                       data_cnt <= data_cnt -1;
                       biss_dat <= c_nEnW(to_integer(data_cnt-7));
                       if (data_cnt = 7) then
                           nEnW_enable <= '0';
                           SM_DATA <= STATE_CRC;
                       end if;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                   elsif sck_timeout_cnt=0 then
                       biss_dat <= '1';
                       crc_reset <= '1';
                       data_enable <= '0';
                       nEnW_enable <= '0';
                       data_cnt <= unsigned(BITS) + c_nEnW_size + c_CRC_size;
                       SM_DATA <= STATE_SYNCH;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                       health_biss_slave<=TO_SVECTOR(1,32);--biss_sck_rising_edge receive timeout error
                   end if;
		   
               -- CRC STATE
               when STATE_CRC =>
                   sck_timeout_cnt<=sck_timeout_cnt-1;
                   -- Transmit the calculated CRC value
                   if (biss_sck_rising_edge = '1') then
                       data_cnt <= data_cnt -1;
                       biss_dat <= crc_o(to_integer(data_cnt-1));
                       if (data_cnt = 1) then
                           SM_DATA <= STATE_STOP;
                       end if;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                   elsif sck_timeout_cnt=0 then
                       biss_dat <= '1';
                       crc_reset <= '1';
                       data_enable <= '0';
                       nEnW_enable <= '0';
                       data_cnt <= unsigned(BITS) + c_nEnW_size + c_CRC_size;
                       SM_DATA <= STATE_SYNCH;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                       health_biss_slave<=TO_SVECTOR(1,32);--biss_sck_rising_edge receive timeout error
                   end if;
		   
               -- STOP STATE
               when STATE_STOP =>
                   -- STOP = 0 during timeout
                   sck_timeout_cnt<=sck_timeout_cnt-1;
                   if (biss_sck_rising_edge = '1') then
                       biss_dat <= '0';
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                   elsif sck_timeout_cnt=0 then
                       biss_dat <= '1';
                       crc_reset <= '1';
                       data_enable <= '0';
                       nEnW_enable <= '0';
                       data_cnt <= unsigned(BITS) + c_nEnW_size + c_CRC_size;
                       SM_DATA <= STATE_SYNCH;
                       sck_timeout_cnt<=c_MAX_TIMEOUT;
                       health_biss_slave<=TO_SVECTOR(1,32);--biss_sck_rising_edge receive timeout error
                   end if;
                   -- Timeout counter
                   -- After timeout output gets set to a one
                   if (timeout_cnt = c_timeout) then
                       biss_dat <= '1';
                       SM_DATA <= STATE_SYNCH;
                       health_biss_slave<=(others => '0');--OK
                   end if;
		   
               when others =>
                   SM_DATA <= STATE_SYNCH;
		   
           end case;
        end if;
    end if;
end process ps_case;



ps_crc_en: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Delay the crc calculation one clock
        calc_enable_i <= (data_enable or nEnW_enable) and biss_sck_rising_edge;
    end if;
end process ps_crc_en;



--calc_enable_i <= (data_enable or nEnW_enable) and biss_sck_rising_edge;
reset <= reset_i or crc_reset;
-- calculate the actual crc value
biss_crc_inst: entity work.biss_crc
port map(
    clk_i         => clk_i,
    reset_i       => reset,
    bitval_i      => biss_dat,
    bitstrb_i     => calc_enable_i,
    crc_o         => crc_o
);


end rtl;
