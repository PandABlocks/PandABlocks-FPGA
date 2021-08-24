
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity endat_sniffer is

generic (g_endat2_1 : natural := 0);
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Configuration interface
    BITS            : in  std_logic_vector(7 downto 0);
    link_up_o       : out std_logic;
    health_o        : out  std_logic_vector(31 downto 0);
    error_o         : out std_logic;
    -- Physical EnDat interface
    endat_sck_i     : in  std_logic;
    endat_dat_i     : in  std_logic;
    -- Block outputs
    posn_o          : out std_logic_vector(31 downto 0)
);

end endat_sniffer;

architecture rtl of endat_sniffer is


component ila_32x8K

    port (
	    clk    : in std_logic;
	    probe0 : IN std_logic_vector(31 downto 0)
        );
        
end component;


-- Ticks in terms of internal serial clock period.
constant SYNCPERIOD         : natural := 125 * 5; -- 5usec


constant c_MODE_COMM_BITS   : unsigned(4 downto 0) := to_unsigned(6,5);


type t_SM_ENDAT is (STATE_T2_CLK1, STATE_T2_CLK2, STATE_MODE_COMM, STATE_T2_CLK1_1, STATE_T2_CLK1_2, STATE_START, STATE_DATA_RANGE, STATE_RECOVER_TIME_tm, STATE_RECOVER_TIME_tR);


-- Number of all bits per EnDat Frame
signal uBITS                : unsigned(7 downto 0);
signal uSTATUS_BITS         : unsigned(7 downto 0);
signal uCRC_BITS            : unsigned(7 downto 0);
signal DATA_BITS            : unsigned(7 downto 0);
signal intBITS              : natural range 0 to 2**BITS'length-1;
signal SM_ENDAT             : t_SM_ENDAT;
signal reset                : std_logic;
signal data_count           : unsigned(7 downto 0);
signal endat_frame          : std_logic;
signal data_valid           : std_logic;
signal nError_valid         : std_logic;
signal crc_valid            : std_logic;
signal data                 : std_logic_vector(31 downto 0);
signal nError               : std_logic_vector(1 downto 0);
signal crc                  : std_logic_vector(4 downto 0);
signal crc_strobe           : std_logic;
signal endat_clock          : std_logic;
signal endat_clock_prev     : std_logic;
signal endat_clock_rise     : std_logic;
signal endat_clock_fall     : std_logic := '0';    
signal endat_data           : std_logic;
signal endat_data_prev      : std_logic;
signal endat_data_rise      : std_logic;
signal link_up              : std_logic;
signal crc_reset            : std_logic;
signal crc_bitstrb          : std_logic;
signal crc_calc             : std_logic_vector(4 downto 0);
signal health_endat_sniffer : std_logic_vector(31 downto 0);
signal mc_count             : unsigned(4 downto 0); 
signal mode_comm            : std_logic_vector(5 downto 0);

signal probe0               : std_logic_vector(31 downto 0);
signal sm_cnt               : std_logic_vector(3 downto 0);

begin



probe0(31) <= endat_clock_fall;   -- 1 bit
probe0(30) <= endat_clock_rise;   -- 1 bit
probe0(29) <= endat_data;         -- 1 bit
probe0(28) <= data_valid;         -- 1 bit
probe0(27) <= nError_valid;       -- 1 bit
probe0(26) <= crc_valid;          -- 1 bit
probe0(25 downto 22) <= sm_cnt;   -- 4 bits         
probe0(21) <= endat_frame;        -- 1 bit
probe0(20 downto 0) <= data(20 downto 0); 


-- Per EnDat Protocol BP3
uBITS        <= unsigned(BITS);
-- EnDat 2.2 = F2 and F1, EnDat2.1 = ALARM 
uSTATUS_BITS <= X"02" when g_endat2_1 = 0 else X"01";  
uCRC_BITS    <= X"05";  -- 6-bits for data

-- Data range = Data + F1+ F2 + CRC
DATA_BITS <= uBITS + uSTATUS_BITS + uCRC_BITS;

--------------------------------------------------------------------------
-- Internal signal assignments
--------------------------------------------------------------------------
endat_clock <= endat_sck_i;
endat_data <= endat_dat_i;

process (clk_i)
begin
    if (rising_edge(clk_i)) then
        endat_clock_prev <= endat_clock;
        endat_data_prev <= endat_data;
    end if;
end process;

-- Internal reset when link is down
--reset <= reset_i or not link_up;
reset <= reset_i;

-- Data latch happens on rising edge of incoming clock
endat_clock_rise <= endat_clock and not endat_clock_prev;
endat_data_rise <= endat_data and not endat_data_prev;

-- Falling edge of incoming clock
endat_clock_fall <= not endat_clock and endat_clock_prev;

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
    clock_i             => endat_clock,
    active_i            => endat_frame,
    link_up_o           => link_up
);

--------------------------------endat_frame-------------------------------
-- EnDat profile BP3 receive State Machine
--------------------------------------------------------------------------
ps_endat_case: process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset = '1') then
            SM_ENDAT <= STATE_T2_CLK1;
            mc_count <= (others => '0');    
            endat_frame <= '0';
        else
        
            -- Bidirectional interface for Position Encoders 
            case SM_ENDAT is
            
                -- Do i need to detect the falling edge ?????????????????
            
                -- Firts clock (2T) 
                when STATE_T2_CLK1 =>
                    sm_cnt <= "0001";
                    mc_count <= (others => '0');
                    if (endat_clock_rise = '1') then     
                        SM_ENDAT <= STATE_T2_CLK2;
                    end if;

                -- Second clock (2T)
                when STATE_T2_CLK2 =>
                    sm_cnt <= "0010";
                    if (endat_clock_rise = '1') then
                        SM_ENDAT <= STATE_MODE_COMM;
                    end if;
                    
                -- Mode Command
                -- The encoders transmit position value 
                -- (Additional data isnt support)          
                when STATE_MODE_COMM =>
                    sm_cnt <= "0011";
                    if (endat_clock_rise = '1') then
                        mc_count <= mc_count +1;
                        mode_comm(to_integer(mc_count)) <= endat_dat_i;
                        -- Six bits for the mode command 
                        if (mc_count = c_MODE_COMM_BITS-1) then
                            mc_count <= (others => '0');
                            SM_ENDAT <= STATE_T2_CLK1_1;
                        end if;
                    end if;

                -- First of the second clock
                when STATE_T2_CLK1_1 => 
                    sm_cnt <= "0100";
                    if (endat_clock_rise = '1') then
                        SM_ENDAT <= STATE_T2_CLK1_2;
                    end if;

                -- Second of the second clock
                when STATE_T2_CLK1_2 =>
                    sm_cnt <= "0101";
                    if (endat_clock_rise = '1') then
                        SM_ENDAT <= STATE_START;
                    end if;    
                    
                -- Start bit 
                when STATE_START =>
                    sm_cnt <= "0110";
                    -- The data should be low before the start bit 
                    -- then goes high to indicate the start bit
                    if (endat_clock_fall = '1' and endat_data = '1') then    
                        SM_ENDAT <= STATE_DATA_RANGE;
                    end if;

                -- Data range = Status + Position value + CRC 
                when STATE_DATA_RANGE => 
                    sm_cnt <= "0111";
                    if (data_count = DATA_BITS) then
                        SM_ENDAT <= STATE_RECOVER_TIME_tm;
                    end if;    
                    
                -- Recovery time 
                -- EnDat 2.1 : 10 to 30 us
                -- EnDat 2.2 : 10 to 30 us or 1.25 to 3.75 us (fc > 1 MHz)
                when STATE_RECOVER_TIME_tm =>
                    sm_cnt <= "1000";
                    -- falling edge detection ?????????????????????????
                    if (endat_sck_i = '1' and endat_dat_i = '1') then
                        SM_ENDAT <= STATE_RECOVER_TIME_tR;
                    end if;
                
                -- tR Max 500ns
                when STATE_RECOVER_TIME_tR => 
                    sm_cnt <= "1001";
                    if (endat_sck_i = '1' and endat_dat_i = '0') then
                        SM_ENDAT <= STATE_T2_CLK1;
                    end if;                        
                
            end case;

            -- Set active endat frame flag for link disconnection
            if (SM_ENDAT = STATE_T2_CLK1 and endat_clock_fall = '1') then
                endat_frame <= '1';
            elsif (SM_ENDAT = STATE_RECOVER_TIME_tm) then
                endat_frame <= '0';
            end if;
        end if;
    end if;
end process ps_endat_case;

--------------------------------------------------------------------------
-- Generate valid flags for Data, Status and CRC parts of the
-- incoming serial data stream
--------------------------------------------------------------------------
ps_endat_result: process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset = '1') then
            data_count <= (others => '0');
            data_valid <= '0';
            nError_valid <= '0';
            crc_valid <= '0';
        else
            -- Keep track of bits received during SCD frame.
            if (SM_ENDAT = STATE_DATA_RANGE) then
                if (endat_clock_fall = '1') then
                    data_count <= data_count + 1;
                end if;
            else
                data_count <= (others => '0');
            end if;

            -- Data range includes all serial data
            if (SM_ENDAT = STATE_DATA_RANGE) then
                -- Status bits first     
                if (data_count <= uSTATUS_BITS-1) then
                    data_valid <= '0';
                    nError_valid <= '1';
                    crc_valid <= '0';
                elsif (data_count <= (uBITS + uSTATUS_BITS-1)) then
                    -- Data bits second
                    data_valid <= '1';
                    nError_valid <= '0';
                    crc_valid <= '0';
                else
                    -- CRC bits third
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
end process ps_endat_result;




ila_inst : entity work.ila_32x8K
    port map (
	        clk => clk_i,
            probe0 => probe0
            );

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
    clock_i         => endat_clock_fall,
    data_i          => endat_data,
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
    clock_i         => endat_clock_fall,
    data_i          => endat_data,
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
    clock_i         => endat_clock_fall,
    data_i          => endat_data,
    data_o          => crc,    
    data_valid_o    => crc_strobe
);


-- Calculate 5-bit CRC from incoming data + status bits
crc_reset <= '1' when (SM_ENDAT = STATE_T2_CLK1) else '0';
crc_bitstrb <= '1' when endat_clock_fall = '1' and data_valid = '1' else '0'; 

endat_crc_inst : entity work.endat_crc
port map (
    clk_i           => clk_i,
    reset_i         => crc_reset,

    bitval_i        => endat_data,
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
--        if reset_i = '1' then
--            health_endat_sniffer <= TO_SVECTOR(2,32);--default timeout error
--        else
--            if link_up = '0' then--timeout error
--               health_endat_sniffer <= TO_SVECTOR(2,32);
--           elsif (crc_strobe = '1') then--crc calc strobe
           if (crc_strobe = '1') then--crc calc strobe
               if (crc /= crc_calc) then--crc error
                  health_endat_sniffer <= TO_SVECTOR(3,32);
               elsif nError /= "00" then--Error received nEnW error bit
                  health_endat_sniffer <= TO_SVECTOR(4,32);
               else--OK   
                  -- range 31 downto 0  
                  FOR I IN data'range LOOP
                      -- LSB transmitted first      
                      posn_o(data'high-I) <= data(I);    
                  END LOOP;
                  health_endat_sniffer <= (others => '0');
               end if;
           end if;
--        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Module status outputs
--   link_down
--   Encoder CRC error
--------------------------------------------------------------------------
link_up_o <= link_up;
health_o <= health_endat_sniffer;
error_o <= crc_strobe when (crc /= crc_calc or nError /= "00") else '0';

end rtl;
