library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sfp_panda_sync_transmit is
    port (
        sysclk_i        : in  std_logic;
        txoutclk_i      : in  std_logic;
        txcharisk_o     : out std_logic_vector(3 downto 0) := (others => '0');
        POSOUT1_i       : in  std_logic_vector(31 downto 0);
        POSOUT2_i       : in  std_logic_vector(31 downto 0);
        POSOUT3_i       : in  std_logic_vector(31 downto 0);
        POSOUT4_i       : in  std_logic_vector(31 downto 0);
        BITOUT_i        : in  std_logic_vector(7 downto 0); 
        txdata_o        : out std_logic_vector(31 downto 0) := (others => '0')
        );

end sfp_panda_sync_transmit;        

architecture rtl of sfp_panda_sync_transmit is

-- Timing diagram below assumes both clocks have same frequency and phase.
-- In reality phase of clocks is arbitrary, and POS data will be 
-- latched up to one cycle earlier or later wrt TX_DATA
       
--    _   _   _   _   _   _   _
--  _| |_| |_| |_| |_| |_| |_| |_       CLOCK
--
--     1   2   3   4   5   6            SEQUENCE 
--  _ ___ ___ ___ ___ ___ ___ _
--  _X___X___X___X___X___X___X_         TX_DATA
--    ___                     _
-- __|   |___________________|          TXCHARISK
--        ___
-- ______|   |_________________         K_SYNC1
--            ___
-- __________|   |_____________         K_SYNC2
--
-- __________________ _________
-- __________________X_________         POS1_LATCH
--
-- ______________________ _____
-- ______________________X_____         POS2_LATCH
--
-- ______ _____________________
-- ______X_____________________         POS3_LATCH
--
-- __________ _________________
-- __________X_________________         POS4_LATCH


subtype t_TX_STATE is INTEGER range 1 to 6;

subtype std8_t is std_logic_vector(7 downto 0);
type std8_array is array(natural range <>) of std8_t;

constant c_k28_5      : std_logic_vector(7 downto 0) := x"BC";

signal POSOUT1_l      : std_logic_vector(POSOUT1_i'range);
signal POSOUT2_l      : std_logic_vector(POSOUT2_i'range);
signal POSOUT3_l      : std_logic_vector(POSOUT3_i'range);
signal POSOUT4_l      : std_logic_vector(POSOUT4_i'range);
signal ksync          : std_logic;
signal ksync_del      : std_logic; 
signal txcharisk_tog  : std_logic := '0';
signal BITOUT_l       : std8_array(0 to 5);

signal seq_num        : unsigned(7 downto 0) := (others => '0');
signal check_byte      : std_logic_vector(7 downto 0);


begin

check_byte <= std_logic_vector(seq_num);

-- TX Sequencer
txdata_driver: process(txoutclk_i)
  -- this variable will synthesise as a register
  variable TX_STATE : t_TX_STATE := 1;
begin
  if rising_edge(txoutclk_i) then

    if TX_STATE = 1 then
        txcharisk_o <= x"1";
        txcharisk_tog <= not txcharisk_tog;
        seq_num       <= seq_num + 1;
    else
        txcharisk_o <= (others => '0');
    end if;

    case TX_STATE is            
      when 1 => txdata_o <= BITOUT_l(0) & POSOUT1_l(31 downto 16) & c_k28_5;
      when 2 => txdata_o <= BITOUT_l(1) & POSOUT1_l(15 downto 0) & POSOUT2_l(31 downto 24);
      when 3 => txdata_o <= BITOUT_l(2) & POSOUT2_l(23 downto 0);
      when 4 => txdata_o <= BITOUT_l(3) & POSOUT3_l(31 downto 8);
      when 5 => txdata_o <= BITOUT_l(4) & POSOUT3_l(7 downto 0) & POSOUT4_l(31 downto 16);
      when 6 => txdata_o <= BITOUT_l(5) & POSOUT4_l(15 downto 0) & check_byte;
    end case;
    
    if TX_STATE = 6 then
      TX_STATE := 1;
    else
      TX_STATE := TX_STATE + 1;
    end if;
 end if;
end process;

ksyncer: entity work.sync_bit
port map(
    clk_i => sysclk_i,
    bit_i => txcharisk_tog,
    bit_o => ksync
);

-- Latch the values of the BITBUS and POSBUS signals
latch_positions: process(sysclk_i)
  -- this variable will synthesise as a shift register
  variable ksync_sr   : std_logic_vector(5 downto 0);
begin
  if rising_edge(sysclk_i) then
    --Detect change of txcharisk and shift into SR
    ksync_del <= ksync;
    ksync_sr := ksync_sr(4 downto 0) & (ksync xor ksync_del);
    if ksync_sr(1) = '1' then 
      POSOUT1_l <= POSOUT1_i;
    end if;
    if ksync_sr(2) = '1' then 
      POSOUT2_l <= POSOUT2_i;
    end if;
    if ksync_sr(4) = '1' then 
      POSOUT3_l <= POSOUT3_i;
    end if;
    if ksync_sr(5) = '1' then 
      POSOUT4_l <= POSOUT4_i;
    end if;
  
    for i in 0 to 5 loop
      if ksync_sr(i) = '1' then
        BITOUT_l(i) <= BITOUT_i;
      end if;
    end loop;
  end if;
end process;

end rtl;

