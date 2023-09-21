library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity sfp_receiver is

    generic (events         : natural := 4);

    port (clk_i              : in  std_logic;
          event_clk_i        : in  std_logic;
          reset_i            : in  std_logic;
          rxdisperr_i        : in  std_logic_vector(1 downto 0);
          rxcharisk_i        : in  std_logic_vector(1 downto 0);
          rxdata_i           : in  std_logic_vector(15 downto 0);
          rxnotintable_i     : in  std_logic_vector(1 downto 0);
          EVENT1             : in  std_logic_vector(31 downto 0);
          EVENT1_WSTB        : in  std_logic;
          EVENT2             : in  std_logic_vector(31 downto 0);
          EVENT2_WSTB        : in  std_logic;
          EVENT3             : in  std_logic_vector(31 downto 0);
          EVENT3_WSTB        : in  std_logic;
          EVENT4             : in  std_logic_vector(31 downto 0);
          EVENT4_WSTB        : in  std_logic;
          rx_link_ok_o       : out std_logic;
          loss_lock_o        : out std_logic;
          rx_error_o         : out std_logic;
          bit1_o             : out std_logic;
          bit2_o             : out std_logic;
          bit3_o             : out std_logic;
          bit4_o             : out std_logic;
          utime_o            : out std_logic_vector(31 downto 0)
          );

end sfp_receiver;


architecture rtl of sfp_receiver is

COMPONENT vio_1
  PORT (
    clk : IN STD_LOGIC;
    probe_in0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe_in1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe_in2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe_in3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe_in4 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe_in5 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe_out0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END COMPONENT;


constant c_zeros : std_logic_vector(1 downto 0) := "00";
constant c_MGT_RX_PRESCALE  : unsigned(9 downto 0) := to_unsigned(1023,10);

constant c_code_reset_event : std_logic_vector(7 downto 0) := X"7D";
constant c_code_seconds_0   : std_logic_vector(7 downto 0) := X"70";
constant c_code_seconds_1   : std_logic_vector(7 downto 0) := X"71";  


type t_event is array(events-1 downto 0) of std_logic_vector(8 downto 0);
type t_dbus_comp is array(events-1 downto 0) of std_logic_vector(7 downto 0);


signal event                 : t_event;
signal dbus_comp             : t_dbus_comp;
signal rx_error              : std_logic;
signal loss_lock             : std_logic;
signal rx_link_ok            : std_logic;
signal rx_error_count        : unsigned(5 downto 0);
signal prescaler             : unsigned(9 downto 0);
signal event_bits            : std_logic_vector(events-1 downto 0);
signal event_bits_dly        : std_logic_vector(events-1 downto 0);
signal event_bits_stretched  : std_logic_vector(events-1 downto 0);
signal event_bits_meta1      : std_logic_vector(events-1 downto 0);
signal event_bits_meta2      : std_logic_vector(events-1 downto 0);
signal event_bits_dlyo       : std_logic_vector(events-1 downto 0);
signal disable_link          : std_logic;
signal EVENT1_WSTB_dly       : std_logic;
signal EVENT1_WSTB_stretched : std_logic;
signal EVENT2_WSTB_dly       : std_logic;
signal EVENT2_WSTB_stretched : std_logic;
signal EVENT3_WSTB_dly       : std_logic;
signal EVENT3_WSTB_stretched : std_logic;
signal EVENT4_WSTB_dly       : std_logic;
signal EVENT4_WSTB_stretched : std_logic;
-- 125MHz to 124.94MHz
signal EVENT1_WSTB_meta1     : std_logic;
signal EVENT1_WSTB_meta2     : std_logic;
signal EVENT2_WSTB_meta1     : std_logic;
signal EVENT2_WSTB_meta2     : std_logic;
signal EVENT3_WSTB_meta1     : std_logic;
signal EVENT3_WSTB_meta2     : std_logic;
signal EVENT4_WSTB_meta1     : std_logic;
signal EVENT4_WSTB_meta2     : std_logic;
signal EVENT1_meta           : std_logic_vector(7 downto 0);
signal EVENT2_meta           : std_logic_vector(7 downto 0);
signal EVENT3_meta           : std_logic_vector(7 downto 0);
signal EVENT4_meta           : std_logic_vector(7 downto 0);

signal utime_shift_reg  : std_logic_vector(31 downto 0);
signal ctr_reset : std_logic;
signal rx_nit_ctr, rx_dis_ctr : unsigned(31 downto 0);
signal rx_nit_dly, rx_dis_dly : std_logic_vector(1 downto 0);

attribute ASYNC_REG : string;
attribute ASYNC_REG of EVENT1_WSTB_meta1 : signal is "TRUE";
attribute ASYNC_REG of EVENT1_WSTB_meta2 : signal is "TRUE";
attribute ASYNC_REG of EVENT2_WSTB_meta1 : signal is "TRUE";
attribute ASYNC_REG of EVENT2_WSTB_meta2 : signal is "TRUE";
attribute ASYNC_REG of EVENT3_WSTB_meta1 : signal is "TRUE";
attribute ASYNC_REG of EVENT3_WSTB_meta2 : signal is "TRUE";
attribute ASYNC_REG of EVENT4_WSTB_meta1 : signal is "TRUE";
attribute ASYNC_REG of EVENT4_WSTB_meta2 : signal is "TRUE";
attribute ASYNC_REG of event_bits_meta1  : signal is "TRUE";
attribute ASYNC_REG of event_bits_meta2  : signal is "TRUE";

type event_code_array is array(natural range <>) of std_logic_vector(7 downto 0);
constant event_codes: event_code_array(0 to 27) := (x"20", x"21", x"23", x"24", x"25", x"26",
    x"2A", x"2C", x"30", x"31", x"32", x"33", x"3C", x"40", x"53", x"54", x"5D", x"5E", x"5F", x"60",
    x"70", x"71", x"75", x"77", x"7A", x"7D", x"00", x"BC");

signal event_code_good : std_logic_vector(event_codes'length downto 0);
signal event_code_error : std_logic;
signal event_err_ctr : unsigned(31 downto 0);

signal dbus_error : std_logic;
signal dbus_err_ctr : unsigned(31 downto 0);

signal disable_link_dly, disable_link_edge : std_logic;
signal disable_link_ctr : unsigned(31 downto 0);
signal total_ind_errors : unsigned(31 downto 0);



begin

-- Valid Control K Characters
  ---------------------------------------------------------
--| Special Code|   Bits    | CURRENT RD - | CURRENT RD + |
--|     Name    | HGF EDCBA | abcdei fghj  | abcdei fghj  |
--|_____________|___________|______________|______________|
--|     K28.0   | 000 11100 | 001111 0100  | 110000 1011  |
--|_____________|___________|______________|______________|
--|     K28.1   | 001 11100 | 001111 1001  | 110000 0110  |
--|_____________|___________|______________|______________|
--|     K28.2   | 010 11100 | 001111 0101  | 110000 1010  |
--|_____________|___________|______________|______________|
--|     K28.3   | 011 11100 | 001111 0011  | 110000 1100  |
--|_____________|___________|______________|______________|
--|     K28.4   | 100 11100 | 001111 0010  | 110000 1101  |
--|_____________|___________|______________|______________|
--|     K28.5   | 101 11100 | 001111 1010  | 110000 0101  | -- THIS IS THE ONE THAT IS USED
--|_____________|___________|______________|______________|
--|     K28.6   | 110 11100 | 001111 0110  | 110000 1001  |
--|_____________|___________|______________|______________|
--|     K28.7   | 111 11100 | 001111 1000  | 110000 0111  |
--|_____________|___________|______________|______________|
--|     K23.7   | 111 10111 | 111010 1000  | 000101 0111  |
--|_____________|___________|______________|______________|
--|     K27.7   | 111 11011 | 110110 1000  | 001001 0111  |
--|_____________|___________|______________|______________|
--|     K29.7   | 111 11101 | 101110 1000  | 010001 0111  |
--|_____________|___________|______________|______________|
--|     K30.7   | 111 11110 | 011110 1000  | 100001 0111  |
--|_____________|___________|______________|______________|


-- 15                      8 7                       0
--  --------------------------------------------------
--  |        DBUS DATA      | KCHAR And EVENT CODES  |
--  --------------------------------------------------

rx_link_ok_o <= rx_link_ok;
loss_lock_o <= loss_lock;
rx_error_o <= rx_error;

-- Unix time 
ps_shift_reg: process(event_clk_i)
begin
    if rising_edge(event_clk_i) then
        if reset_i = '1' then
            utime_shift_reg <= (others => '0');
            utime_o <= (others => '0');
        else
            -- Shift a '0' into the shift register		
            if rxdata_i(7 downto 0) = c_code_seconds_0 then
                utime_shift_reg <= utime_shift_reg(30 downto 0) & '0';
            -- Shift a '1' into the shift register
            elsif rxdata_i(7 downto 0) = c_code_seconds_1 then
                utime_shift_reg <= utime_shift_reg(30 downto 0) & '1';
            -- Shift the unix time out 
            elsif rxdata_i(7 downto 0) = c_code_reset_event then
                utime_shift_reg <= (others => '0');
                utime_o <= utime_shift_reg;
            end if;
        end if;            
    end if;
end process ps_shift_reg;   


-- Assign the array outputs to individual bits
-- Done this to stop the outputs being high for 2 clocks instead of one
-- There is an issue with the clock cycle this being
--
-- ____/''''\____/''''\____/''''\____/''''\____/''''\____/''''\____/''''\____
--     |         |         |         |         |         |         |            All rising edge happen at the same time
--          ||        ||        ||        ||        ||        ||        ||      One clock extra on the high cycle taken from the low cycle
-- ____/'''''\___/'''''\___/'''''\___/'''''\___/'''''\___/'''''\___/'''''\___
--
bit1_o <= event_bits_meta2(0) and not event_bits_dlyo(0) when EVENT1(8) = '0' else event_bits_meta2(0);
bit2_o <= event_bits_meta2(1) and not event_bits_dlyo(1) when EVENT2(8) = '0' else event_bits_meta2(1);
bit3_o <= event_bits_meta2(2) and not event_bits_dlyo(2) when EVENT3(8) = '0' else event_bits_meta2(2);
bit4_o <= event_bits_meta2(3) and not event_bits_dlyo(3) when EVENT4(8) = '0' else event_bits_meta2(3);



ps_125MHz: process(clk_i)
begin
    if rising_edge(clk_i) then
        lp_meta: for i in 0 to events-1 loop
            -- Resynch to the 125MHz domain
            event_bits_meta1(i) <= event_bits_stretched(i);
            event_bits_meta2(i) <= event_bits_meta1(i);
            event_bits_dlyo(i) <= event_bits_meta2(i);
        end loop lp_meta;
    end if;
end process ps_125MHz;


-- Generate a delay of the strobe to be used to stretch the strobe signal
ps_125MHz_stretched: process(clk_i)
begin
    if rising_edge(clk_i) then
        EVENT1_WSTB_dly <= EVENT1_WSTB;
        EVENT2_WSTB_dly <= EVENT2_WSTB;
        EVENT3_WSTB_dly <= EVENT3_WSTB;
        EVENT4_WSTB_dly <= EVENT4_WSTB;
    end if;
end process ps_125MHz_stretched;


-- Stretch the EVENT WSTB as the one clock strobe could be missed
EVENT1_WSTB_stretched <= EVENT1_WSTB_dly or EVENT1_WSTB;
EVENT2_WSTB_stretched <= EVENT2_WSTB_dly or EVENT2_WSTB;
EVENT3_WSTB_stretched <= EVENT3_WSTB_dly or EVENT3_WSTB;
EVENT4_WSTB_stretched <= EVENT4_WSTB_dly or EVENT4_WSTB;


-- Register strobe going from 125MHz to 124.92MHz domain
ps_124MHz: process(event_clk_i)
begin
    if rising_edge(event_clk_i) then
        EVENT1_WSTB_meta1 <= EVENT1_WSTB_stretched;
        EVENT1_WSTB_meta2 <= EVENT1_WSTB_meta1;
        EVENT2_WSTB_meta1 <= EVENT2_WSTB_stretched;
        EVENT2_WSTB_meta2 <= EVENT2_WSTB_meta1;
        EVENT3_WSTB_meta1 <= EVENT3_WSTB_stretched;
        EVENT3_WSTB_meta2 <= EVENT3_WSTB_meta1;
        EVENT4_WSTB_meta1 <= EVENT4_WSTB_stretched;
        EVENT4_WSTB_meta2 <= EVENT4_WSTB_meta1;
        -- EVENT 1
        if EVENT1_WSTB_meta2 = '1' then
            event(0) <= EVENT1(8 downto 0);
            EVENT1_meta <= EVENT1(7 downto 0);
        end if;
        -- EVENT 2
        if EVENT2_WSTB_meta2 = '1' then
            event(1) <= EVENT2(8 downto 0);
            EVENT2_meta <= EVENT2(7 downto 0);
        end if;
        -- EVENT 3
        if EVENT3_WSTB_meta2 = '1' then
            event(2) <= EVENT3(8 downto 0);
            EVENT3_meta <= EVENT3(7 downto 0);
        end if;
        -- EVENT 4
        if EVENT4_WSTB_meta2 = '1' then
            event(3) <= EVENT4(8 downto 0);
            EVENT4_meta <= EVENT4(7 downto 0);
        end if;
    end if;
end process ps_124MHz;


-- AND the EVENTs with the data coming in and do a bit comparison
dbus_comp(0) <= EVENT1_meta and rxdata_i(15 downto 8);
dbus_comp(1) <= EVENT2_meta and rxdata_i(15 downto 8);
dbus_comp(2) <= EVENT3_meta and rxdata_i(15 downto 8);
dbus_comp(3) <= EVENT4_meta and rxdata_i(15 downto 8);


-- Bits stretched
event_bits_stretched <= event_bits_dly or event_bits;


ps_event_dbus: process(event_clk_i)
begin
    if rising_edge(event_clk_i) then
        -- Generate a delay of the strobe to be used to stretch the strobe signal
        event_bits_dly <= event_bits;
        if rx_link_ok = '1' then
            lp_events: for i in events-1 downto 0 loop
                -- DBUS         bit comparison
                -- Event Codes  value comparison
                -- Top bit indicates which bus to use
                -- event_dbus(8) = '1' - RXDATA(15 downto 8)
                -- event_dbus(8) = '0' - RXDATA(7 downto 0)
                -- DBUS         RXDATA(15 downto 8)    1 = DBUS
                -- EVENT_CODES  RXDATA(7 downto 0)     0 = EVENT_CODES
                -- DBus these are bit comparisons
                if event(i)(8) = '1' then -- DBUS event
                    if rxcharisk_i(1) = '0' and rxnotintable_i(1) = '0' and rxdisperr_i(1) = '0' then
                        if dbus_comp(i) /= x"00" then
                            event_bits(i) <= '1';
                        else
                            event_bits(i) <= '0';
                        end if;
                    else
                        null;  -- Don't update event_bits if error occured 
                    end if;
                else -- EVENT CODE
                    if rxcharisk_i(0) = '0' and rxnotintable_i(0) = '0' and rxdisperr_i(0) = '0' then
                        if event(i)(7 downto 0) = rxdata_i(7 downto 0) then
                            event_bits(i) <= '1';
                        else
                            event_bits(i) <= '0';
                        end if;
                    else
                        event_bits(i) <= '0'; -- Zero event_bits when error or comma detected on EVENT_CODE
                    end if;
                end if;
            end loop lp_events;
        end if;
    end if;
end process ps_event_dbus;



-- This is a modified version of the code used in the open source event receiver
-- It is hard to know when the link is up as the only way of doing this is to use
-- rxnotintable and rxdisperr signals.
-- rxnotintable and rxdisperr errors do occur when the link is up, I run the the event
-- receiver for four days counting the number of times these two errors happened the
-- error rate was days 4 error count 12272
ps_link_lost:process(event_clk_i)
begin
    if rising_edge(event_clk_i) then
        if reset_i = '1' then
            prescaler <= (others => '0');
            disable_link <= '1';
        else
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
    end if;
end process ps_link_lost;

error_ctr : process(event_clk_i)
begin
    if rising_edge(event_clk_i) then
        rx_nit_dly <= rxnotintable_i;
        rx_dis_dly <= rxdisperr_i;
        if ctr_reset = '1' then
            rx_nit_ctr <= (others => '0');
            rx_dis_ctr <= (others => '0');
            event_err_ctr <= (others => '0');
            dbus_err_ctr <= (others => '0');
            disable_link_ctr <= (others => '0');
            total_ind_errors <= (others => '0');
        else
            if rxnotintable_i /= c_zeros then
                rx_nit_ctr <= rx_nit_ctr + 1;
            end if;
            if rxdisperr_i /= c_zeros then
                rx_dis_ctr <= rx_dis_ctr + 1;
            end if;
            if event_code_error = '1' then
                event_err_ctr <= event_err_ctr + 1;
            end if;
            if dbus_error = '1' then
                dbus_err_ctr <= dbus_err_ctr + 1;
            end if;
            if disable_link_edge = '1' then
                disable_link_ctr <= disable_link_ctr + 1;
            end if;
            if dbus_error = '1' or event_code_error = '1' or rx_dis_dly /= c_zeros or rx_nit_dly /= c_zeros then
                total_ind_errors <= total_ind_errors + 1;
            end if;
        end if;
    end if;
end process;

event_code_error <= '1' when unsigned(event_code_good) = 0 else '0';
disable_link_edge <= disable_link and not disable_link_dly;

code_checker: process(event_clk_i)
begin
    if rising_edge(event_clk_i) then
        disable_link_dly <= disable_link;

        if rxdata_i(11 downto 8) /= x"0" and rxdisperr_i(1) = '0' and rxnotintable_i(1) = '0' then
            dbus_error <= '1';
        else
            dbus_error <= '0';
        end if;

        for i in event_codes'range loop
            if rxdata_i(7 downto 0) = event_codes(i) and rxdisperr_i(0) = '0' and rxnotintable_i(0) = '0' then
                event_code_good(i) <= '1';
            else
                event_code_good(i) <= '0'; 
            end if;
        end loop;
    end if;
end process;


error_vio : vio_1
  PORT MAP (
    clk => event_clk_i,
    probe_in0 => std_logic_vector(rx_nit_ctr),
    probe_in1 => std_logic_vector(rx_dis_ctr),
    probe_in2 => std_logic_vector(event_err_ctr),
    probe_in3 => std_logic_vector(dbus_err_ctr),
    probe_in4 => std_logic_vector(disable_link_ctr),
    probe_in5 => std_logic_vector(total_ind_errors),
    probe_out0(0) => ctr_reset
  );



end rtl;
