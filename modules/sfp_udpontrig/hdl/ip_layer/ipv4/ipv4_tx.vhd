--------------------------------------------------------------------------------
-- Company:
-- Engineer:            Peter Fall
--
-- Create Date:    16:20:42 06/01/2011
-- Design Name:
-- Module Name:    IPv4_TX - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--              handle simple IP TX
--              doesnt handle segmentation
--              dest MAC addr resolution through ARP layer
--              Handle IPv4 protocol
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - fixed up setting of tx_result control defaults
-- Revision 0.03 - Added data_out_first
-- Revision 0.04 - Added handling of broadcast address
-- Revision 0.05 - Fix cks calc when add of high bits causes another ovf
-- Additional Comments:
--
-- Thierry GARREL (ELSYS-Design)
--    restructure code : tab 2 spaces, add comments,
--    reorder some signals declarations
--
--------------------------------------------------------------------------------


--==============================================================================
-- Libraries Declaration
--==============================================================================
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library work;
  use work.axi_types.all;
  use work.ipv4_types.all;
  use work.arp_types.all;


--==============================================================================
-- Entity Declaration
--==============================================================================
entity ipv4_tx is
  generic (
    ILA_DEBUG             : boolean := FALSE
  );
  port (
    -- IP Layer signals (in)
    ip_tx_start           : in  std_logic;
    ip_tx                 : in  ipv4_tx_type;                   -- IP tx cxns
    -- IP Layer signals (out)
    ip_tx_result          : out std_logic_vector(1 downto 0);  -- tx status (changes during transmission)
    ip_tx_data_out_ready  : out std_logic;                      -- indicates IP TX is ready to take data

    -- system signals (in)
    clk                   : in  std_logic;                      -- same clock used to clock mac data and ip data
    reset                 : in  std_logic;
    our_ip_address        : in  std_logic_vector(31 downto 0);
    our_mac_address       : in  std_logic_vector(47 downto 0);

    -- ARP lookup signals
    arp_req_req           : out arp_req_req_type;
    arp_req_rslt          : in  arp_req_rslt_type;

    -- MAC layer TX signals
    mac_tx_req            : out std_logic;                      -- indicates that ip wants access to channel (stays up for as long as tx)
    mac_tx_granted        : in  std_logic;                      -- indicates that access to channel has been granted
    mac_data_out_ready    : in  std_logic;                      -- indicates system ready to consume data
    mac_data_out_valid    : out std_logic;                      -- indicates data out is valid
    mac_data_out_first    : out std_logic;                      -- with data out valid indicates the first byte of a frame
    mac_data_out_last     : out std_logic;                      -- with data out valid indicates the last byte of a frame
    mac_data_out          : out std_logic_vector(7 downto 0)    -- ethernet frame (from dst mac addr through to last byte of frame)
    );
end ipv4_tx;


--==============================================================================
-- Architecture Declaration
--==============================================================================
architecture Behavioral of ipv4_tx is

  -- ILA IP used for debugging purpose
  component ila_32x8k
  port (
    clk     : in std_logic;
    probe0  : in std_logic_vector(31 downto 0)
  );
  end component;

  -------------------------------
  -- FSM definitions
  -------------------------------
  type tx_state_type is (
    IDLE,
    WAIT_MAC,                           -- waiting for response from ARP for mac lookup
    WAIT_CHN,                           -- waiting for tx access to MAC channel
    SEND_ETH_HDR,                       -- sending the ethernet header
    SEND_IP_HDR,                        -- sending the IP header
    SEND_USER_DATA                      -- sending the users data
  );

  type crc_state_type is (
    IDLE,
    TOT_LEN,
    ID,
    FLAGS,
    TTL,
    CKS,
    SAH,
    SAL,
    DAH,
    DAL,
    ADDOVF,
    FINAL,
    WAIT_END
  );

  type count_mode_type    is (RST, INCR, HOLD);
  type settable_cnt_type  is (RST, SET, INCR, HOLD);
  type set_clr_type       is (SET, CLR, HOLD);

  -------------------------------
  -- Constants
  -------------------------------

  -- Configuration

  constant IP_TTL : std_logic_vector(7 downto 0) := x"08";--x"80";


  -------------------------------
  -- Internal signals
  -------------------------------

  -- TX state variables
  signal set_tx_state                   : std_logic;
  signal next_tx_state                  : tx_state_type;
  signal tx_state                       : tx_state_type;

  attribute fsm_encoding                : string;
  attribute fsm_safe_state              : string;
  attribute mark_debug                  : string;

  attribute fsm_encoding of tx_state    : signal is "one_hot";
  attribute fsm_safe_state of tx_state  : signal is "auto_safe_state"; -- Use Hamming-3 encoded to ensure tolerance of SEU
  attribute mark_debug of tx_state      : signal is "true";


  signal tx_count                       : unsigned (11 downto 0);
  signal tx_result_reg                  : std_logic_vector(1 downto 0);
  signal tx_mac                         : std_logic_vector(47 downto 0);
  signal tx_mac_chn_reqd                : std_logic;
  signal tx_hdr_cks                     : std_logic_vector(23 downto 0);
  signal mac_lookup_req                 : std_logic;

  signal crc_state                      : crc_state_type;
  signal arp_req_ip_reg                 : std_logic_vector(31 downto 0);
  signal mac_data_out_ready_reg         : std_logic;

  -- tx control signals
  signal next_tx_result                 : std_logic_vector(1 downto 0);
  signal set_tx_result                  : std_logic;
  signal tx_mac_value                   : std_logic_vector(47 downto 0);
  signal set_tx_mac                     : std_logic;
  signal tx_count_val                   : unsigned (11 downto 0);
  signal tx_count_mode                  : settable_cnt_type;
  signal tx_data                        : std_logic_vector(7 downto 0);
  signal set_last                       : std_logic;
  signal set_chn_reqd                   : set_clr_type;
  signal set_mac_lku_req                : set_clr_type;
  signal tx_data_valid                  : std_logic;   -- indicates whether data is valid to tx or not

  -- tx temp signals
  signal total_length                   : std_logic_vector(15 downto 0);  -- computed combinatorially from header size


  -------------------------------
  -- functions
  -------------------------------

  function inv_if_one(s1 : std_logic_vector; en : std_logic) return std_logic_vector is
    --this function inverts all the bits of a vector if
    --'en' is '1'.
    variable Z : std_logic_vector(s1'high downto s1'low);
  begin
    for i in (s1'low) to s1'high loop
      Z(i) := en xor s1(i);
    end loop;
    return Z;
  end inv_if_one;  -- end function


-- IP datagram header format
--
--      0          4          8                      16      19             24                    31
--      --------------------------------------------------------------------------------------------
--      | Version  | *Header  |    Service Type      |        Total Length including header        |
--      |   (4)    |  Length  |     (ignored)        |                 (in bytes)                  |
--      --------------------------------------------------------------------------------------------
--      |           Identification                   | Flags |       Fragment Offset               |
--      |                                            |       |      (in 32 bit words)              |
--      --------------------------------------------------------------------------------------------
--      |    Time To Live     |       Protocol       |             Header Checksum                 |
--      |     (ignored)       |                      |                                             |
--      --------------------------------------------------------------------------------------------
--      |                                   Source IP Address                                      |
--      |                                                                                          |
--      --------------------------------------------------------------------------------------------
--      |                                 Destination IP Address                                   |
--      |                                                                                          |
--      --------------------------------------------------------------------------------------------
--      |                          Options (if any - ignored)               |       Padding        |
--      |                                                                   |      (if needed)     |
--      --------------------------------------------------------------------------------------------
--      |                                          Data                                            |
--      |                                                                                          |
--      --------------------------------------------------------------------------------------------
--      |                                          ....                                            |
--      |                                                                                          |
--      --------------------------------------------------------------------------------------------
--
-- * - in 32 bit words

  -------------------------------
  -- CHIPSCOPE ILA probes
  -------------------------------
  signal probe6               : std_logic_vector(31 downto 0);

  attribute keep : string;--keep name for ila probes
  attribute keep of tx_state       : signal is "true";
  attribute keep of tx_count       : signal is "true";




--==============================================================================
-- Beginning of Code
--==============================================================================
begin
  -----------------------------------------------------------------------
  -- combinatorial process to implement FSM and determine control signals
  -----------------------------------------------------------------------

  tx_combinatorial : process(
    -- input signals
    ip_tx_start, ip_tx, our_ip_address, our_mac_address, arp_req_rslt,  --clk,
    mac_tx_granted, mac_data_out_ready,
    -- state variables
    tx_state, tx_count, tx_result_reg, tx_mac, tx_mac_chn_reqd,
    mac_lookup_req, tx_hdr_cks, arp_req_ip_reg, mac_data_out_ready_reg,
    -- control signals
    next_tx_state, set_tx_state, next_tx_result, set_tx_result, tx_mac_value, set_tx_mac, tx_count_mode,
    tx_data, set_last, set_chn_reqd, set_mac_lku_req, total_length,
    tx_data_valid, tx_count_val
    )
  begin
    -- set output followers
    ip_tx_result           <= tx_result_reg;
    mac_tx_req             <= tx_mac_chn_reqd;
    arp_req_req.lookup_req <= mac_lookup_req;
    arp_req_req.ip         <= arp_req_ip_reg;

    -- set initial values for combinatorial outputs
    mac_data_out_first <= '0';

    case tx_state is
      when SEND_ETH_HDR | SEND_IP_HDR =>
        mac_data_out      <= tx_data;
        tx_data_valid     <= mac_data_out_ready;  -- generated internally
        mac_data_out_last <= set_last;

      when SEND_USER_DATA =>
        mac_data_out      <= ip_tx.data.data_out;
        tx_data_valid     <= ip_tx.data.data_out_valid;
        mac_data_out_last <= ip_tx.data.data_out_last;

      when others =>
        mac_data_out      <= (others => '0');
        tx_data_valid     <= '0';       -- not transmitting during this phase
        mac_data_out_last <= '0';
    end case;

    mac_data_out_valid <= tx_data_valid and mac_data_out_ready;

    -- set signal defaults
    next_tx_state   <= IDLE;
    set_tx_state    <= '0';
    tx_count_mode   <= HOLD;
    tx_data         <= x"00";
    set_last        <= '0';
    set_tx_mac      <= '0';
    set_chn_reqd    <= HOLD;
    set_mac_lku_req <= HOLD;
    next_tx_result  <= IPTX_RESULT_NONE;
    set_tx_result   <= '0';
    tx_count_val    <= (others => '0');
    tx_mac_value    <= (others => '0');

    -- set temp signals
    total_length <= std_logic_vector(unsigned(ip_tx.hdr.data_length) + 20);  -- total length = user data length + header length (bytes)

    -- TX FSM
    case tx_state is
      when IDLE =>
        ip_tx_data_out_ready <= '0';  -- in this state, we are unable to accept user data for tx
        tx_count_mode        <= RST;
        set_chn_reqd         <= CLR;
        if ip_tx_start = '1' then
                                        -- check header count for error if too high
          if unsigned(ip_tx.hdr.data_length) > 1480 then
            next_tx_result <= IPTX_RESULT_ERR;
            set_tx_result  <= '1';
          else
            next_tx_result <= IPTX_RESULT_SENDING;
            set_tx_result  <= '1';

                                        -- TODO - check if we already have the mac addr for this ip, if so, bypass the WAIT_MAC state

            if ip_tx.hdr.dst_ip_addr = IP_BC_ADDR then
                                        -- for IP broadcast, dont need to look up the MAC addr
              tx_mac_value  <= MAC_BC_ADDR;
              set_tx_mac    <= '1';
              next_tx_state <= WAIT_CHN;
              set_tx_state  <= '1';
            else
                                        -- need to req the mac address for this ip
              set_mac_lku_req <= SET;
              next_tx_state   <= WAIT_MAC;
              set_tx_state    <= '1';
            end if;
          end if;
        else
          set_mac_lku_req <= CLR;
        end if;

      when WAIT_MAC =>
        ip_tx_data_out_ready <= '0';  -- in this state, we are unable to accept user data for tx
        set_mac_lku_req      <= CLR;  -- clear the request - will have been latched in the ARP layer
        if arp_req_rslt.got_mac = '1' then
                                        -- save the MAC we got back from the ARP lookup
          tx_mac_value <= arp_req_rslt.mac;
          set_tx_mac   <= '1';
          set_chn_reqd <= SET;
                                        -- check for optimise when already have the channel
          if mac_tx_granted = '1' then
                                        -- ready to send data
            next_tx_state <= SEND_ETH_HDR;
            set_tx_state  <= '1';
          else
            next_tx_state <= WAIT_CHN;
            set_tx_state  <= '1';
          end if;
        elsif arp_req_rslt.got_err = '1' then
          set_mac_lku_req <= CLR;
          next_tx_result  <= IPTX_RESULT_ERR;
          set_tx_result   <= '1';
          next_tx_state   <= IDLE;
          set_tx_state    <= '1';
        end if;

      when WAIT_CHN =>
        ip_tx_data_out_ready <= '0';  -- in this state, we are unable to accept user data for tx
        if mac_tx_granted = '1' then
                                        -- ready to send data
          next_tx_state <= SEND_ETH_HDR;
          set_tx_state  <= '1';
        end if;
        -- probably should handle a timeout here

      when SEND_ETH_HDR =>
        ip_tx_data_out_ready <= '0';  -- in this state, we are unable to accept user data for tx
        if mac_data_out_ready = '1' then
          if tx_count = x"00d" then
            tx_count_mode <= RST;
            next_tx_state <= SEND_IP_HDR;
            set_tx_state  <= '1';
          else
            tx_count_mode <= INCR;
          end if;
          case tx_count is
            when x"000" =>
              mac_data_out_first <= mac_data_out_ready;
              tx_data            <= tx_mac (47 downto 40);  -- trg = mac from ARP lookup

            when x"001" => tx_data <= tx_mac (39 downto 32);
            when x"002" => tx_data <= tx_mac (31 downto 24);
            when x"003" => tx_data <= tx_mac (23 downto 16);
            when x"004" => tx_data <= tx_mac (15 downto 8);
            when x"005" => tx_data <= tx_mac (7 downto 0);
            when x"006" => tx_data <= our_mac_address (47 downto 40);  -- src = our mac
            when x"007" => tx_data <= our_mac_address (39 downto 32);
            when x"008" => tx_data <= our_mac_address (31 downto 24);
            when x"009" => tx_data <= our_mac_address (23 downto 16);
            when x"00a" => tx_data <= our_mac_address (15 downto 8);
            when x"00b" => tx_data <= our_mac_address (7 downto 0);
            when x"00c" => tx_data <= x"08";  -- pkt type = 0800 : IP
            when x"00d" => tx_data <= x"00";
            when others =>
                                        -- shouldnt get here - handle as error
              next_tx_result <= IPTX_RESULT_ERR;
              set_tx_result  <= '1';
              next_tx_state  <= IDLE;
              set_tx_state   <= '1';
          end case;
        end if;

      when SEND_IP_HDR =>
        ip_tx_data_out_ready <= '0';  -- in this state, we are unable to accept user data for tx
        if mac_data_out_ready = '1' then
          if tx_count = x"013" then
            tx_count_val  <= x"001";
            tx_count_mode <= SET;
            next_tx_state <= SEND_USER_DATA;
            set_tx_state  <= '1';
          else
            tx_count_mode <= INCR;
          end if;
          case tx_count is
            when x"000" => tx_data <= x"45";  -- v4, 5 words in hdr
            when x"001" => tx_data <= x"00";  -- service type
            when x"002" => tx_data <= total_length (15 downto 8);            -- total length
            when x"003" => tx_data <= total_length (7 downto 0);
            when x"004" => tx_data <= x"00";  -- identification
            when x"005" => tx_data <= x"00";
            when x"006" => tx_data <= x"00";  -- flags and fragment offset
            when x"007" => tx_data <= x"00";
            when x"008" => tx_data <= IP_TTL;                                -- TTL
            when x"009" => tx_data <= ip_tx.hdr.protocol;                    -- protocol
            when x"00a" => tx_data <= tx_hdr_cks (15 downto 8);              -- HDR checksum
            when x"00b" => tx_data <= tx_hdr_cks (7 downto 0);               -- HDR checksum
            when x"00c" => tx_data <= our_ip_address (31 downto 24);         -- src ip
            when x"00d" => tx_data <= our_ip_address (23 downto 16);
            when x"00e" => tx_data <= our_ip_address (15 downto 8);
            when x"00f" => tx_data <= our_ip_address (7 downto 0);
            when x"010" => tx_data <= ip_tx.hdr.dst_ip_addr (31 downto 24);  -- dst ip
            when x"011" => tx_data <= ip_tx.hdr.dst_ip_addr (23 downto 16);
            when x"012" => tx_data <= ip_tx.hdr.dst_ip_addr (15 downto 8);
            when x"013" => tx_data <= ip_tx.hdr.dst_ip_addr (7 downto 0);
            when others =>
                                        -- shouldnt get here - handle as error
              next_tx_result <= IPTX_RESULT_ERR;
              set_tx_result  <= '1';
              next_tx_state  <= IDLE;
              set_tx_state   <= '1';
          end case;
        end if;

      when SEND_USER_DATA =>
        ip_tx_data_out_ready <= mac_data_out_ready;-- and mac_data_out_ready_reg;  -- in this state, we are always ready to accept user data for tx
        if mac_data_out_ready = '1' then
          if ip_tx.data.data_out_valid = '1' or tx_count = x"000" then
                                                                                -- only increment if ready and valid has been subsequently established, otherwise data count moves on too fast
            if unsigned(tx_count) = unsigned(ip_tx.hdr.data_length) then
                                        -- TX terminated due to count - end normally
              set_last       <= '1';
              set_chn_reqd   <= CLR;
              tx_data        <= ip_tx.data.data_out;
              next_tx_result <= IPTX_RESULT_SENT;
              set_tx_result  <= '1';
              next_tx_state  <= IDLE;
              set_tx_state   <= '1';
              if ip_tx.data.data_out_last = '0' then
                next_tx_result <= IPTX_RESULT_ERR;
              end if;
            elsif ip_tx.data.data_out_last = '1' then
                                                                                -- TX terminated due to receiving last indication from upstream - end with error
              set_last       <= '1';
              set_chn_reqd   <= CLR;
              tx_data        <= ip_tx.data.data_out;
              next_tx_result <= IPTX_RESULT_ERR;
              set_tx_result  <= '1';
              next_tx_state  <= IDLE;
              set_tx_state   <= '1';
            else
                                        -- TX continues
              tx_count_mode <= INCR;
              tx_data       <= ip_tx.data.data_out;
            end if;
          end if;
        end if;

    end case;
  end process;

  -----------------------------------------------------------------------------
  -- sequential process to action control signals and change states and outputs
  -----------------------------------------------------------------------------

  tx_sequential : process (clk)--, reset, mac_data_out_ready_reg)
  begin
--    if rising_edge(clk) then
--      mac_data_out_ready_reg <= mac_data_out_ready;
--    else
--      mac_data_out_ready_reg <= mac_data_out_ready_reg;
--    end if;

    if rising_edge(clk) then
      if reset = '1' then
        -- reset state variables
        tx_state        <= IDLE;
        tx_count        <= x"000";
        tx_result_reg   <= IPTX_RESULT_NONE;
        tx_mac          <= (others => '0');
        tx_mac_chn_reqd <= '0';
        mac_lookup_req  <= '0';

      else
        -- Next tx_state processing
        if set_tx_state = '1' then
          tx_state <= next_tx_state;
        else
          tx_state <= tx_state;
        end if;

        -- tx result processing
        if set_tx_result = '1' then
          tx_result_reg <= next_tx_result;
        else
          tx_result_reg <= tx_result_reg;
        end if;

        -- control arp lookup request
        case set_mac_lku_req is
          when SET =>
            arp_req_ip_reg <= ip_tx.hdr.dst_ip_addr;
            mac_lookup_req <= '1';

          when CLR =>
            mac_lookup_req <= '0';
            arp_req_ip_reg <= arp_req_ip_reg;

          when HOLD =>
            mac_lookup_req <= mac_lookup_req;
            arp_req_ip_reg <= arp_req_ip_reg;
        end case;

        -- save MAC
        if set_tx_mac = '1' then
          tx_mac <= tx_mac_value;
        else
          tx_mac <= tx_mac;
        end if;

        -- control access request to mac tx chn
        case set_chn_reqd is
          when SET  => tx_mac_chn_reqd <= '1';
          when CLR  => tx_mac_chn_reqd <= '0';
          when HOLD => tx_mac_chn_reqd <= tx_mac_chn_reqd;
        end case;

        -- tx_count processing
        case tx_count_mode is
          when RST  => tx_count <= x"000";
          when SET  => tx_count <= tx_count_val;
          when INCR => tx_count <= tx_count + 1;
          when HOLD => tx_count <= tx_count;
        end case;

      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Process to calculate CRC in parallel with pkt out processing
  -- this process must yield a valid CRC before it is required to be used in the hdr
  -----------------------------------------------------------------------------

  crc : process (clk)--, reset)
  begin
    if rising_edge(clk) then
      case crc_state is
        when IDLE =>
          if ip_tx_start = '1' then
            tx_hdr_cks <= x"004500";    -- vers & hdr len & service
            crc_state  <= TOT_LEN;
          end if;

        when TOT_LEN =>
          tx_hdr_cks <= std_logic_vector(unsigned(tx_hdr_cks) + unsigned(total_length));
          crc_state  <= ID;

        when ID =>
          tx_hdr_cks <= tx_hdr_cks;
          crc_state  <= FLAGS;

        when FLAGS =>
          tx_hdr_cks <= tx_hdr_cks;
          crc_state  <= TTL;

        when TTL =>
          tx_hdr_cks <= std_logic_vector(unsigned(tx_hdr_cks) + unsigned(IP_TTL & ip_tx.hdr.protocol));
          crc_state  <= CKS;

        when CKS =>
          tx_hdr_cks <= tx_hdr_cks;
          crc_state  <= SAH;

        when SAH =>
          tx_hdr_cks <= std_logic_vector(unsigned(tx_hdr_cks) + unsigned(our_ip_address(31 downto 16)));
          crc_state  <= SAL;

        when SAL =>
          tx_hdr_cks <= std_logic_vector(unsigned(tx_hdr_cks) + unsigned(our_ip_address(15 downto 0)));
          crc_state  <= DAH;

        when DAH =>
          tx_hdr_cks <= std_logic_vector(unsigned(tx_hdr_cks) + unsigned(ip_tx.hdr.dst_ip_addr(31 downto 16)));
          crc_state  <= DAL;

        when DAL =>
          tx_hdr_cks <= std_logic_vector(unsigned(tx_hdr_cks) + unsigned(ip_tx.hdr.dst_ip_addr(15 downto 0)));
          crc_state  <= ADDOVF;

        when ADDOVF =>
          tx_hdr_cks <= std_logic_vector((unsigned(tx_hdr_cks) and x"00ffff")+ unsigned(tx_hdr_cks(23 downto 16)));
          crc_state  <= FINAL;

        when FINAL =>
          tx_hdr_cks <= inv_if_one(std_logic_vector(unsigned(tx_hdr_cks) + unsigned(tx_hdr_cks(23 downto 16))), '1');
          crc_state  <= WAIT_END;

        when WAIT_END =>
          tx_hdr_cks <= tx_hdr_cks;
          if ip_tx_start = '0' then
            crc_state <= IDLE;
          else
            crc_state <= WAIT_END;
          end if;


      end case;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Chipscope ILA Debug purpose
  ---------------------------------------------------------------------------
  ILA_GEN : if ILA_DEBUG generate
    My_chipscope_ila_probe_IP_TX_6 : ila_32x8K
    port map (
      clk     => clk,
      probe0  => probe6
    );

    probe6(11 downto 0)<=--tx_state&
                         std_logic_vector(tx_count);

    probe6(31 downto 12)<=(others=>'0');

  end generate;


end Behavioral;
--==============================================================================
-- End of Code
--==============================================================================

