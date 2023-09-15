library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.support.all;

entity sfp_panda_sync_receiver is
    port (sysclk_i          : in  std_logic;
          reset_i           : in  std_logic;
          rxoutclk_i        : in  std_logic;   
          rxdisperr_i       : in  std_logic_vector(3 downto 0);
          rxcharisk_i       : in  std_logic_vector(3 downto 0);
          rxdata_i          : in  std_logic_vector(31 downto 0);
          rxnotintable_i    : in  std_logic_vector(3 downto 0);
          check_bits_i      : in  std_logic_vector(31 downto 0);
          rx_link_ok_o      : out std_logic;
          loss_lock_o       : out std_logic;
          rx_error_o        : out std_logic;
          BITIN_o           : out std_logic_vector(7 downto 0);   
          POSIN1_o          : out std_logic_vector(31 downto 0);
          POSIN2_o          : out std_logic_vector(31 downto 0);
          POSIN3_o          : out std_logic_vector(31 downto 0);
          POSIN4_o          : out std_logic_vector(31 downto 0);
          health_o          : out std_logic_vector(31 downto 0)
          );

end sfp_panda_sync_receiver;


architecture rtl of sfp_panda_sync_receiver is

-- Timing diagram below assumes both clocks have same frequency and phase.
-- In reality phase of clocks is arbitrary, and POS data will be 
-- latched up to one cycle earlier or later wrt TX_DATA
       
--    _   _   _   _   _   _   _
--  _| |_| |_| |_| |_| |_| |_| |_       CLOCK
--
--     1   2   3   4   5   6            SEQUENCE 
--  _ ___ ___ ___ ___ ___ ___ _
--  _X___X___X___X___X___X___X_         RX_DATA
--    ___                     _
-- __|   |___________________|          RXCHARISK
--        ___
-- ______|   |_________________         K_SYNC1
--            ___
-- __________|   |_____________         K_SYNC2
--
-- __________________ _________
-- __________________X_________         POSIN1
--
-- ______________________ _____
-- ______________________X_____         POSIN2
--
-- ______ _____________________
-- ______X_____________________         POSIN3
--
-- __________ _________________
-- __________X_________________         POSIN4

constant c_zeros            : std_logic_vector(3 downto 0) := "0000";
-- Packet start (deprecated)
constant c_k28_0            : std_logic_vector(7 downto 0) := x"1C";
-- Word alignment
constant c_k28_5            : std_logic_vector(7 downto 0) := x"BC";
constant c_MGT_RX_PRESCALE  : unsigned(9 downto 0) := to_unsigned(1023,10);

constant SETTLE_PERIOD      : natural := 12500; -- 100 microsec at 125MHz

subtype t_RX_STATE is INTEGER range 1 to 6;

subtype std8_t is std_logic_vector(7 downto 0);
type std8_array is array(natural range <>) of std8_t;

signal RX_STATE : t_RX_STATE := 1;

signal rx_error         : std_logic;
signal loss_lock        : std_logic;
signal rx_link_ok       : std_logic := '0';
signal rx_link_ok_sys   : std_logic := '0';
signal rx_link_good     : std_logic;
signal rx_error_count   : unsigned(5 downto 0);
signal prescaler        : unsigned(9 downto 0) := (others => '0');
signal disable_link     : std_logic := '1';
signal POSIN1_l         : std_logic_vector(POSIN1_o'range);
signal POSIN2_l         : std_logic_vector(POSIN2_o'range);
signal POSIN3_l         : std_logic_vector(POSIN3_o'range);
signal POSIN4_l         : std_logic_vector(POSIN4_o'range);
signal ksync            : std_logic;
signal ksync_del        : std_logic; 
signal rxcharisk_tog    : std_logic := '0';
signal BITIN_l          : std8_array(0 to 5);
signal seq_num          : unsigned(7 downto 0) := (others => '0');
signal check_byte       : std_logic_vector(7 downto 0);
signal check_byte_prev  : unsigned(7 downto 0);

-- signals required for error checking
signal deprecated_protocol            : std_logic;
signal protocol_error                 : std_logic;
signal deprecated_protocol_prev       : std_logic;
signal protocol_error_prev            : std_logic;
signal deprecated_protocol_tog        : std_logic := '0';
signal protocol_error_tog             : std_logic := '0';
signal deprecated_protocol_sync       : std_logic;
signal protocol_err_sync              : std_logic;
signal deprecated_protocol_sync_prev  : std_logic;
signal protocol_err_sync_prev         : std_logic;
signal deprecated_protocol_sys        : std_logic;
signal protocol_err_sys               : std_logic;
signal checkbyte_err                  : std_logic;
signal checkbyte_err_prev             : std_logic;
signal checkbyte_err_tog              : std_logic := '0';
signal checkbyte_err_sync             : std_logic;
signal checkbyte_err_sync_prev        : std_logic;
signal checkbyte_err_sys              : std_logic;
signal link_down_latch                : std_logic;

begin

-- Assign outputs

loss_lock_o <= loss_lock;
rx_error_o <= rx_error;
rx_link_ok_o <= rx_link_ok_sys;

-- Synchronise rx_link_ok onto sysclk domain
rx_link_sync : entity work.sync_bit
    port map(
     clk_i => sysclk_i,
     bit_i => rx_link_ok,
     bit_o => rx_link_ok_sys
);

-- This is a modified version of the code used in the open source event receiver
-- It is hard to know when the link is up as the only way of doing this is to use
-- rxnotintable and rxdisperr signals.
ps_link_lost:process(rxoutclk_i)
begin
  if rising_edge(rxoutclk_i) then
    -- Check the status of the link every 1023 clocks
    if prescaler = 0 then
        -- 0.008441037ms
        -- The link has gone down or is up
        if disable_link = '0' then
            rx_link_ok <= '1';
        else
            rx_link_ok <= '0';
        end if;

        if disable_link = '1' then
            disable_link <= '0';
        end if;

    end if;

    -- Check the link status loss_lock if
    -- not set then set the signal disable_link
    if disable_link = '0' then
        if loss_lock = '1' then
            disable_link <= '1';
        end if;
    end if;
    -- Link is down
    if rx_link_ok = '0' then
        loss_lock <= rx_error;
    else
        loss_lock <= rx_error_count(5);
    end if;
    -- Error has occured
    -- Check the link for errors
    if rx_link_ok = '1' then
        if rx_error = '1' then
            -- Subtract one from error count (count down error count)
            if rx_error_count(5) = '0' then
                rx_error_count <= rx_error_count -1;
            end if;
        else
            -- Add one to the error count to handle occasional errors happening
            if prescaler = 0 and (rx_error_count(5) = '1' or rx_error_count(4) = '0') then
                rx_error_count <= rx_error_count +1;
            end if;
        end if;
    -- Link up set the count down error count to 31
    else
        rx_error_count <= "011111";
    end if;
    -- RXNOTINTABLE :- The received data value is not a valid 10b/8b value
    -- RXDISPERR    :- Indicates data corruption or tranmission of a invalid control character
    if (rxnotintable_i /= c_zeros or rxdisperr_i /= c_zeros) then
        rx_error <= '1';
    else
        rx_error <= '0';
    end if;
    -- 1023 clock count up
    if prescaler = c_MGT_RX_PRESCALE -1 then
        prescaler <= (others => '0');
    else
        prescaler <= prescaler +1;
    end if;
  end if;
end process ps_link_lost;

rxdata_reader: process(rxoutclk_i)
  -- this variable will synthesise as a register
  variable RX_STATE : t_RX_STATE := 1;
begin
  if rising_edge(rxoutclk_i) then

    -- RX sequencer
    if rxcharisk_i = x"1" then
      rxcharisk_tog <= not rxcharisk_tog;
      case (rxdata_i(7 downto 0)) is 
        when c_k28_5 => 
          RX_STATE := 1;
          deprecated_protocol <= '0';
          protocol_error <= '0';
        when c_k28_0 => 
          deprecated_protocol <= '1';
          protocol_error <= '0';
        when others  =>
          deprecated_protocol <= '0'; 
          protocol_error <= '1';
      end case;

      -- Do some error checking on the check-byte
      if to_integer(unsigned(check_bits_i)) = 1 and check_byte /= std_logic_vector(check_byte_prev + 1) then
        checkbyte_err <= '1';
      elsif to_integer(unsigned(check_bits_i)) = 0 and check_byte /= x"00" then
        checkbyte_err <= '1';
      else
        checkbyte_err <= '0';
      end if;
    elsif RX_STATE = 6 then
      -- this statement should never be reached
      protocol_error <= '1'; 
      deprecated_protocol <= '0';
      checkbyte_err <= '0';
    else
      RX_STATE := RX_STATE + 1;
      protocol_error <= '0'; 
      deprecated_protocol <= '0';
      checkbyte_err <= '0';
    end if;

    BITIN_l(RX_STATE-1) <= rxdata_i(31 downto 24);

    case (RX_STATE) is
      when 1 =>
        POSIN1_l(31 downto 16) <= rxdata_i(23 downto  8);
      when 2 =>
        POSIN1_l(15 downto  0) <= rxdata_i(23 downto  8);
        POSIN2_l(31 downto 24) <= rxdata_i(7  downto  0);
      when 3 =>
        POSIN2_l(23 downto  0) <= rxdata_i(23 downto  0);
      when 4 => 
        POSIN3_l(31 downto  8) <= rxdata_i(23 downto  0);
      when 5 =>
        POSIN3_l(7  downto  0) <= rxdata_i(23 downto 16);
        POSIN4_l(31 downto 16) <= rxdata_i(15 downto  0);
      when 6 =>
        POSIN4_l(15 downto  0) <= rxdata_i(23 downto  8);
        check_byte             <= rxdata_i(7  downto  0);
        check_byte_prev        <= unsigned(check_byte);
    end case;

    -- Capture the rising egde of the error flags
    deprecated_protocol_prev <= deprecated_protocol;
    if deprecated_protocol = '1' and deprecated_protocol_prev = '0' then
      deprecated_protocol_tog <= not deprecated_protocol_tog;
    end if;

    protocol_error_prev <= protocol_error;
    if protocol_error = '1' and protocol_error_prev = '0' then
      protocol_error_tog <= not protocol_error_tog;
    end if;

    checkbyte_err_prev <= checkbyte_err;
    if checkbyte_err = '1' and checkbyte_err_prev = '0' then
       checkbyte_err_tog <= not checkbyte_err_tog;
    end if;

  end if;
end process;

-- Synchronise kchar edge onto sysclk domain
ksyncer: entity work.sync_bit
port map(
    clk_i => sysclk_i,
    bit_i => rxcharisk_tog,
    bit_o => ksync
);

-- Read the POS and BIT signals on the sysclk domain
read_latched_vals: process(sysclk_i)
  -- this variable will synthesise as a shift register
  variable ksync_sr   : std_logic_vector(5 downto 0);
begin
  if rising_edge(sysclk_i) then
    ksync_del <= ksync; 
    ksync_sr := ksync_sr(4 downto 0) & (ksync xor ksync_del);
    if (rx_link_good = '1') then
      if ksync_sr(1) = '1' then
        POSIN1_o <= POSIN1_l; 
      end if;
      if ksync_sr(2) = '1' then
        POSIN2_o <= POSIN2_l; 
      end if;
      if ksync_sr(4) = '1' then
        POSIN3_o <= POSIN3_l; 
      end if;
      if ksync_sr(5) = '1' then
        POSIN4_o <= POSIN4_l; 
      end if;

      for i in 0 to 5 loop
        if ksync_sr(i) = '1' then
          BITIN_o <= BITIN_l(i);
        end if;
      end loop;
    end if;
  end if;
end process;

-- Latch errors on sysclk domain

depr_prot_sync: entity work.sync_bit
port map(
    clk_i => sysclk_i,
    bit_i => deprecated_protocol_tog,
    bit_o => deprecated_protocol_sync
);

prot_err_sync: entity work.sync_bit
port map(
    clk_i => sysclk_i,
    bit_i => protocol_error_tog,
    bit_o => protocol_err_sync
);

chckbyte_sync: entity work.sync_bit
port map(
    clk_i => sysclk_i,
    bit_i => checkbyte_err_tog,
    bit_o => checkbyte_err_sync
);

health_sys: process(sysclk_i)
begin
  if rising_edge(sysclk_i) then

    deprecated_protocol_sync_prev <= deprecated_protocol_sync;
    protocol_err_sync_prev <= protocol_err_sync;
    checkbyte_err_sync_prev <= checkbyte_err_sync;

    if reset_i = '1' then
      link_down_latch <= '0';
      deprecated_protocol_sys <= '0';
      protocol_err_sys <= '0';
      checkbyte_err_sys <= '0';
    else
      if rx_link_good = '1' then
        if rx_link_ok_sys = '0' then
          link_down_latch <= '1';
        end if;
        if (deprecated_protocol_sync xor deprecated_protocol_sync_prev) = '1' then
          deprecated_protocol_sys <= '1';
        end if;
        if (protocol_err_sync xor protocol_err_sync_prev) = '1' then
          protocol_err_sys <= '1';
        end if;
        if (checkbyte_err_sync xor checkbyte_err_sync_prev) = '1' then
          checkbyte_err_sys <= '1';
        end if;
      end if;
    end if;

    if rx_link_good = '0' or link_down_latch = '1' then
      -- flag when the link is down, regardless of whether latch is reset
      health_o <= std_logic_vector(to_unsigned(1,32));
    elsif deprecated_protocol_sys = '1' then
      health_o <= std_logic_vector(to_unsigned(2,32));
    elsif protocol_err_sys = '1' then
      health_o <= std_logic_vector(to_unsigned(3,32));
    elsif checkbyte_err_sys = '1' then
      health_o <= std_logic_vector(to_unsigned(4,32));
    else
      health_o <= std_logic_vector(to_unsigned(0,32));
    end if;
  end if;
end process;

--Wait for settling period before asserting link_good
rx_link_ok_timer: process(sysclk_i)
  variable timer_val : unsigned(LOG2(SETTLE_PERIOD) downto 0);
begin
  if rising_edge(sysclk_i) then
    if reset_i = '1' or rx_link_ok_sys = '0' then
      timer_val := (others => '0');
      rx_link_good <= '0';
    elsif timer_val = SETTLE_PERIOD then
      rx_link_good <= rx_link_ok_sys;
    else
      timer_val := timer_val + 1;
    end if;
  end if;
end process;

end rtl;

