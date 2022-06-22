--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : PandABox FPGA
-- Design name    : sfp_udpontrig
-- Module name    : udp_ping.vhd
-- Purpose        : ICMP layer which responds only to echo requests with an echo reply
--                  Any other ICMP messages are discarded (ignored).
--                  Can respond to any ping containing 0 to 1472 bytes of data.
--                  which is the maximum payload for Ethernet II Frame
--                  (1500 bytes - 20 bytes of IPv4 header - 8 bytes of ICMP header)
--
-- Author         : Thierry GARREL (ELSYS-Design) [TGA]
-- Synthesizable  : YES
-- Language       : VHDL-93
--
--------------------------------------------------------------------------------
-- Copyright (c) 2021 Synchrotron SOLEIL - L'Orme des Merisiers Saint-Aubin
-- BP 48 91192 Gif-sur-Yvette Cedex  - https://www.synchrotron-soleil.fr
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
  use work.icmp_types.all;


-- =============================================================================
-- Entity Declaration
--==============================================================================
entity udp_ping is
  generic (
    -- Limit the amount of logic cells used to store ICMP optional data (synthesis only)
    -- Windows ping issues 32 bytes of ICMP data by default
    -- Linux   ping issues 64 bytes of ICMP data by default (8 bytes of header & 56 bytes of optional data)
    -- Theoritical max ping size with non fragmented IPv4 frames is 1472 bytes, ie 1500 - 20 (Ipv4 header) -8 (icmp header)
    MAX_PING_SIZE         : natural := 256                     -- Maximum pkt size. Larger echo requests will be ignored. (max 1472)
  );
  port (
    -- System signals (in)
    clk                   : in  std_logic;                      -- asynchronous clock
    reset                 : in  std_logic;                      -- synchronous active high reset input
    -- IP layer RX signals (in)
    ip_rx_start           : in  std_logic;                      -- indicates receipt of ip frame
    ip_rx                 : in  ipv4_rx_type;                   -- IP rx cxns
    -- status signals (out)
    icmp_pkt_count        : out std_logic_vector(7 downto 0);   -- number of ICMP pkts received for us
    icmp_pkt_err          : out std_logic;                      -- indicate an errored ICMP pkt (type <> x"0800" or pkt greater than 1472 bytes)
    icmp_pkt_err_count    : out std_logic_vector(7 downto 0);   -- number of errored ICMP pkts received for us
    -- IP layer TX signals (out)
    ip_tx_start           : out  std_logic;
    ip_tx                 : out ipv4_tx_type;                   -- IP tx cxns
    ip_tx_result          : in  std_logic_vector(1 downto 0);   -- tx status (changes during transmission)
    ip_tx_data_out_ready  : in  std_logic                       -- indicates IP TX is ready to take data
    );
end udp_ping;

-- ip_rx (ipv4_rx_type)
-- .hdr   : .is_valid .protocol(7:0) .data_length(15:0) .src_ip_addr(31:0) .num_frame_errors(7:0) .last_error_code(3:0) .is_broadcast
-- .data  : .data_in(7:0) .data_in_valid .data_in_last

-- ip_tx (ipv4_tx_type)
-- .hdr    : .protocol(7:0) .data_length(15:0) .dst_ip_addr(31:0)
-- .data   : .data_out(7:0) .data_out_valid .data_out_last


-------------------------------------------------------
-- description:  PING protocol.
-------------------------------------------------------
--
-- ICMP : RF972 https://tools.ietf.org/html/rfc792
--
-- Couche 3  : Encapsule dans un datagramme IP
-- Entete IP : Protocole = 1 (ICMP) Type de Service = 0
-- voir https://fr.wikipedia.org/wiki/Internet_Control_Message_Protocol
-- et https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml


-- Paquet ICMP encapsule dans un datagrame IP : https://en.wikipedia.org/wiki/IPv4
-- ================================================================================
-- IP datagram header format ( https://www.frameip.com/entete-ip ; https://rlworkman.net/howtos/iptables/chunkyhtml/x178.html )
--
--
--    0          4          8                      16      19             24                    31     bytes
--    --------------------------------------------------------------------------------------------
--    | Version  |  IHL     |    Service Type      |        Total Length including header        |     4   ^
--    --------------------------------------------------------------------------------------------         |
--    |           Identification                   | Flags |  Fragment Offset (in 32 bit words)  |     4   |
--    --------------------------------------------------------------------------------------------         |
--    |    TTL (ignored)    |     Protocol 0x01    |             Header Checksum                 |     4   | 20 bytes (160 bits) min
--    --------------------------------------------------------------------------------------------         |
--    |                                   Source IP Address                                      |     4   |
--    --------------------------------------------------------------------------------------------         |
--    |                                 Destination IP Address                                   |     4   v
--    --------------------------------------------------------------------------------------------
--    |                                   Options (if IHL > 5)                                   |     0 - 40 bytes
--    --------------------------------------------------------------------------------------------
-- Version (4 bits)       : "0100" - IP V4
-- IHL     (4 bits)       : Internet header length (in 32 bits words) default = "0101" (5) => 20 bytes
-- Version/IHL            = 0x"45"
-- Total Length (16 bits) : packet length including header and data (in bytes)
          --                Data Length = Total Length ( IHL * 4 )
-- Protocol (8 bits)      :  1 - 0x01 - ICMP
--                          17 - 0x11 - UDP
--
--
-- ICMP data protocol unit header format ( https://www.frameip.com/entete-icmp/ )
-- Standard echo request and reply ICMP header : 8 bytes minimum
--
--    0                      8                     16                                           31     bytes
--    --------------------------------------------------------------------------------------------
--    |         Type         |        Code         |                Checksum                     | (1)  4   |
--    --------------------------------------------------------------------------------------------          | 8 bytes min
--    |                Identifier                  |              Sequence_number                |      4   |
--    --------------------------------------------------------------------------------------------
--    |                                      Optional Data                                       |
--    --------------------------------------------------------------------------------------------
--    |                                          ....                                            |
--    --------------------------------------------------------------------------------------------
--
-- Type = Type de message (8 bits)            PING : Echo Request  : Type 8 Code 0
-- Code = Code de l'erreur (8 bits)                  Echo Reply    : Type 0 Code 0
-- Checksum (16 bits) calculee sur la partie specifique a l'ICMP (sans l'entete IP)
-- (1) used by all of the ICMP types ( https://rlworkman.net/howtos/iptables/chunkyhtml/x281.html )
--
-- Identifiant et Numero de Sequence ou Bourrage (32 bits)
--
-- The related ping utility is implemented using the ICMP echo request and echo reply messages.
-- https://en.wikipedia.org/wiki/Ping_(networking_utility)
--
-- The echo reply generated in response to an echo request must include the exact payload received in the request.
--
-- Checksum : the ICMP checksum includes the ICMP header bytes. Since the ICMP header Type field
-- changes from 0x08 for a ping request to 0x00 for a ping response, the ping response is indeed
-- supposed to be different by 0x0800.
--
-- The Ping response checksum is computed by adding 0x0800 to the Ping Request checksum while
-- recording carry-outs. At the end of the checksum, all the accumulated carry-outs are added back
-- (as if they were more 16 bit chunk of data).
--

--==============================================================================
-- Entity Architecture
--==============================================================================
architecture behavioral of udp_ping is

-- RX side :  receive IP datagram with protocol = ICMP (0x01) :
--            detects Echo Request (Type 08 Code 00)
--            prepare Echo Reply response

-- TX side :  send IP datagram with protocol = ICMP (0x01)
--            set dest_ip_addr = src_ip_addr
--            and Echo Reply response  (Type 00 code 00) with same data received in Echo Request

  --------------------------------
  -- Constants
  --------------------------------
  constant icmp_checksum_offset   : std_logic_vector(15 downto 0) := x"0800"; -- 2048


  -------------------------------------------------
  -- Common type definitions
  -------------------------------------------------
  type count_mode_type            is (RST, INCR, HOLD);
  type settable_count_mode_type   is (RST, SET_VAL, INCR, HOLD);
  type set_clr_type               is (SET, CLR, HOLD);
  type rx_event_type              is (NO_EVENT, DATA);

  type rx_state_type              is (IDLE, ICMP_HEADER, USER_DATA, WAIT_END, ERR);
  type tx_state_type              is (IDLE, PAUSE, SEND_ICMP_HEADER, SEND_USER_DATA);

  -- ICMP data array : use to save ICMP Echo Request optional data
  type icmp_data_array_type is array(1 to MAX_PING_SIZE) of std_logic_vector(7 downto 0);

  --------------------------------
  -- inputs followers signals
  --------------------------------
  signal rx_start           : std_logic;                -- ip_rx_start input register
  signal rx_in              : ipv4_rx_type;             -- ip_rx       input register
  signal rx_event           : rx_event_type;            -- DATA, NO_EVENT
  signal rx_data_length     : unsigned(15 downto 0);    -- data_length extracted from ip_rx header  ip_rx.hdr.data_length

  -------------------------------------------------
  -- RX side states and signals definition
  -------------------------------------------------
  -- rx state variables
  signal set_rx_state       : std_logic;      -- go to next state else stay in current state
  signal next_rx_state      : rx_state_type;  -- next state register
  signal rx_state           : rx_state_type;  -- state register
  -- rx control signals
  signal rx_count_mode      : settable_count_mode_type;
  signal rx_count           : unsigned(15 downto 0);

  signal set_pkt_cnt        : std_logic;
  signal rx_pkt_count       : unsigned(7 downto 0);  -- number of ICMP pkts received for us

  signal set_pkt_type_err   : std_logic; -- received pkt type_code is different from x"0800" (Echo Request)
  signal set_pkt_size_err   : std_logic; -- received pkt size is greater than 1472 bytes (MAX_PING_SIZE)
  signal reset_pkt_err      : std_logic;
  signal rx_pkt_err_reg     : std_logic;
  signal rx_pkt_err_count   : unsigned(7 downto 0);  -- number of errorred ICMP pkts received for us


  -- capture ICMP header fields
  signal set_src_ip         : std_logic; -- capture ip_rx header
  signal set_checksum_H     : std_logic; -- capture ICMP header checksum field msb
  signal set_checksum_L     : std_logic; -- capture ICMP header checksum field lsb
  signal set_identifier_H   : std_logic; -- capture ICMP header Identificier field msb
  signal set_identifier_L   : std_logic; -- capture ICMP header Identificier field lsb
  signal set_seq_number_H   : std_logic; -- capture ICMP header Sequence_number field msb
  signal set_seq_number_L   : std_logic; -- capture ICMP header Sequence_number field lsb

  signal icmp_rx_header     : icmp_header_type;       -- src_ip_addr  data_length  msg_type msg_code checksum identifier  seq_number
  signal icmp_rx_data_array : icmp_data_array_type;   -- ICMP data array memory

  signal icmp_reply_cks_full : std_logic_vector(31 downto 0); -- Compute checksum on 32 bits to record all the carry-outs
  signal icmp_reply_checksum : std_logic_vector(15 downto 0); -- Ping reply checksum

  signal set_echo_request   : std_logic;      -- indicate we have receive an ICMP Echo Request rame (1 clk pulse)
  signal icmp_echo_request  : std_logic;
  signal icmp_echo_reply    : std_logic;      -- indicates to create ICMP Echo reply response


  -------------------------------------------------
  -- TX side states and signals definition
  -------------------------------------------------
  -- tx state variables
  signal set_tx_state       : std_logic;
  signal next_tx_state      : tx_state_type;
  signal tx_state           : tx_state_type;  -- TX current state register
    -- tx control signals
  signal tx_count_mode      : settable_count_mode_type;
  signal tx_count           : unsigned(15 downto 0);

  signal set_ip_tx_start    : set_clr_type;
  signal ip_tx_start_reg    : std_logic;          -- precurseur ip_tx_start (out)

  signal tx_data_out        : std_logic_vector(7 downto 0);
  signal tx_data_valid      : std_logic;
  signal tx_data_last       : std_logic;

  --------------------------------
  -- outputs followers signals
  --------------------------------
  signal ip_tx_header       : ipv4_tx_header_type; -- .protocol(7:0) .data_length(15:0) .dst_ip_addr(31:0)
  signal ip_tx_data         : axi_out_type;


  --------------------------------
  -- FSM encoding attributes
  --------------------------------
  attribute fsm_encoding    : string;
  attribute fsm_safe_state  : string;
  attribute mark_debug      : string;

  attribute fsm_encoding   of rx_state : signal is "one_hot";
  attribute fsm_safe_state of rx_state : signal is "auto_safe_state"; -- Use Hamming-3 encoded to ensure tolerance of SEU
  attribute mark_debug     of rx_state : signal is "true";

  attribute fsm_encoding   of tx_state : signal is "one_hot";
  attribute fsm_safe_state of tx_state : signal is "auto_safe_state"; -- Use Hamming-3 encoded to ensure tolerance of SEU
  attribute mark_debug     of tx_state : signal is "true";

  attribute keep                    : string;--keep name for ila probes
  attribute keep of rx_state        : signal is "true";
  attribute keep of rx_count        : signal is "true";
  attribute keep of tx_state        : signal is "true";
  attribute keep of tx_count        : signal is "true";



--==============================================================================
-- Beginning of Code
--==============================================================================
begin

  -------------------------------------------------------------
  -- Process : input_proc
  -- Description : check ip_rx validity
  -------------------------------------------------------------
  input_proc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        rx_start          <= '0';
        rx_in.hdr         <= C_IPV4_RX_HEADER_NULL;
        rx_in.data        <= C_AXI_IN_DATA_NULL;
        rx_event          <= NO_EVENT;
        rx_data_length    <= (others=>'0');
      else
        -- ip_rx input register
        rx_start <= ip_rx_start;
        rx_in    <= ip_rx;
        -- rx_event
        if (ip_rx.data.data_in_valid = '1') then
          rx_event <= DATA;
        else
          rx_event <= NO_EVENT;
        end if;
        -- determine user_data length : substract ICMP header length (8 bytes) from IPv4 data_length
        if (ip_rx.hdr.is_valid = '1') then
          rx_data_length <= unsigned(ip_rx.hdr.data_length) - 8 ;
        end if;
      end if; -- reset
    end if; -- clk
  end process input_proc;



  -- ***************************************************************************
  --                             ICMP Rx part
  -- ***************************************************************************

  ------------------------------------------------------------------------------
  -- Process: rx_comb_proc
  -- RX combinatorial process to implement FSM and determine control signals
  ------------------------------------------------------------------------------
  rx_comb_proc : process (
    -- input signals
    rx_start, rx_in, rx_event, rx_data_length,
    -- state variables
    rx_state, rx_count,
    -- control signals
    next_rx_state, set_rx_state, set_pkt_cnt, set_pkt_type_err, set_pkt_size_err, reset_pkt_err, rx_count_mode,
    set_src_ip, set_checksum_H, set_checksum_L, set_identifier_H, set_identifier_L, set_seq_number_H, set_seq_number_L
    )
  begin

    -- set signal defaults
    rx_count_mode       <= HOLD;
    next_rx_state       <= IDLE;    -- prevent from infering a latch
    set_rx_state        <= '0';
    set_pkt_cnt         <= '0';
    set_pkt_type_err    <= '0';
    set_pkt_size_err    <= '0';
    reset_pkt_err       <= '0';

    set_src_ip          <= '0';
    set_checksum_H      <= '0'; set_checksum_L    <= '0';
    set_identifier_H    <= '0'; set_identifier_L  <= '0';
    set_seq_number_H    <= '0'; set_seq_number_L  <= '0';
    set_echo_request    <= '0';


    -- RX_FSM combinatorial
    case rx_state is
      -----------------
      -- IDLE
      -----------------
      when IDLE =>
        rx_count_mode <= RST;

        case rx_event is
          when NO_EVENT =>                          -- (nothing to do)
          when DATA     =>
            if rx_in.hdr.protocol = C_ICMP_PROTOCOL then      -- x"01"

              -- ignore pkts that are not ICMP type 08 (Echo Request)
              --    and pkts larger than 1472 bytes (MAX_PING_SIZE)
              if (rx_in.data.data_in /= C_ICMP_TYPE_08) or (rx_data_length > MAX_PING_SIZE) then
                rx_count_mode     <= RST;
                next_rx_state     <= WAIT_END;
                set_rx_state      <= '1';

                if (rx_in.data.data_in /= C_ICMP_TYPE_08) then
                  set_pkt_type_err  <= '1';
                end if;
                if (rx_data_length > MAX_PING_SIZE) then
                  set_pkt_size_err  <= '1'; -- rise pkt_size error
                end if;

              else
                  rx_count_mode   <= INCR;
                  next_rx_state   <= ICMP_HEADER;
                  set_rx_state    <= '1';
              end if;

            -- not ICMP protocol - ignore this pkt
            else
              next_rx_state   <= WAIT_END;
              set_rx_state    <= '1';
            end if;
        end case;

      -----------------
      -- ICMP_HEADER
      -----------------
      when ICMP_HEADER =>
        case rx_event is
          when NO_EVENT =>              -- (nothing to do)
          when DATA     =>

            -- handle early frame termination
            if rx_in.data.data_in_last = '1' and (rx_data_length /= 0) then
              rx_count_mode   <= RST;
              next_rx_state   <= IDLE;
              set_rx_state    <= '1';
            else
              -- default values
              rx_count_mode   <= INCR;
              next_rx_state   <= ICMP_HEADER;

              case rx_count is
                -- ICMP header
                when x"0001" => -- ignore pkts that are not ICMP Code 00 (Echo Request)
                                if (rx_in.data.data_in /= C_ICMP_CODE_00) then
                                  rx_count_mode     <= RST;
                                  next_rx_state     <= WAIT_END;
                                  set_rx_state      <= '1';
                                  set_pkt_type_err  <= '1';  -- rise pkt_type error
                                else
                                  set_src_ip <= '1';  -- capture ip_rx header
                                end if;

                when x"0002" => set_checksum_H    <= '1'; -- capture ICMP header checksum field msb
                when x"0003" => set_checksum_L    <= '1';   -- capture ICMP header checksum field lsb
                when x"0004" => set_identifier_H  <= '1'; -- capture ICMP header Identificier field msb
                when x"0005" => set_identifier_L  <= '1'; -- capture ICMP header Identificier field lsb
                when x"0006" => set_seq_number_H  <= '1'; -- capture ICMP header Sequence_number field msb
                when x"0007" => set_seq_number_L  <= '1'; -- capture ICMP header Sequence_number field lsb

                                set_echo_request  <= '1'; -- we have an ICMP Echo Request (Type 08)
                                                          -- do not need to wait last data to send the Ping response s
                                                          -- since the Ping response checksum only differs of 2048 (x"0800")
                                                          -- from the incoming Ping request checksum

                                set_pkt_cnt     <= '1'; -- INCR; -- count another pkt received

                                if rx_data_length = 0 then    -- ping with 0 bytes of data
                                  rx_count_mode   <= RST;
                                  next_rx_state   <= IDLE;
                                  set_rx_state    <= '1';
                                else
                                  rx_count_mode   <= SET_VAL; -- rx_count restarts at 1
                                  next_rx_state   <= USER_DATA;
                                  set_rx_state    <= '1';
                                end if;

                when others =>  -- ignore other bytes in ICMP header
              end case;
            end if;
        end case;

      when USER_DATA =>
        case rx_event is
          when NO_EVENT =>              -- (nothing to do)
              -- check for early frame termination  ??? TODO (TGA)
              -- TODO need to mark frame as errored
              next_rx_state   <= IDLE;
              set_rx_state    <= '1';

          when DATA =>                  -- note: data gets transfered upstream as part of "outputs followers" processing

            -- In this state rx_count counts from 1 to rx_data_length (and rx_data_length /= 0)

            if rx_count = (rx_data_length) then     -- end of frame
              rx_count_mode <= RST;

              if rx_in.data.data_in_last = '1' then
                next_rx_state <= IDLE;
                set_rx_state  <= '1';
              else
                next_rx_state <= WAIT_END;
                set_rx_state  <= '1';
              end if;

            else
              rx_count_mode <= INCR;
              -- check for early frame termination
              -- TODO need to mark frame as errored
              if rx_in.data.data_in_last = '1' then
                next_rx_state <= IDLE;
                set_rx_state  <= '1';
              end if;
            end if;
        end case;

      when ERR =>
        if rx_in.data.data_in_last = '0' then
          next_rx_state <= WAIT_END;
          set_rx_state    <= '1';
        else
          next_rx_state <= IDLE;
          set_rx_state    <= '1';
        end if;

      when WAIT_END =>
        case rx_event is
          when NO_EVENT =>              -- (nothing to do)
          when DATA     =>
            if rx_in.data.data_in_last = '1' then
              next_rx_state   <= IDLE;
              set_rx_state    <= '1';
              reset_pkt_err   <= '1';
            end if;
        end case; -- rx_event

    end case; -- rx_state;
  end process rx_comb_proc;


  -----------------------------------------------------------------------------------
  -- Process: rx_seq_proc
  -- RX sequential process to action control signals and change states and outputs
  -----------------------------------------------------------------------------------
  rx_seq_proc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- reset state variables
        rx_state            <= IDLE;
        rx_count            <= x"0000";
        rx_pkt_count        <= (others=>'0');
        rx_pkt_err_reg      <= '0';
        rx_pkt_err_count    <= (others=>'0');

        ip_tx_start_reg     <= '0';

        icmp_echo_request   <= '0';
        icmp_rx_header      <= C_ICMP_HEADER_NULL;

        icmp_reply_cks_full <= (others=>'0');
        icmp_reply_checksum <= x"0000";

      else
        icmp_echo_request <= set_echo_request;
        -- Next rx_state processing
        if set_rx_state = '1' then
          rx_state <= next_rx_state;
        else
          rx_state <= rx_state;
        end if;

        -- rx_count processing
        case rx_count_mode is
          when RST     => rx_count <= x"0000";
          when SET_VAL => rx_count <= x"0001";
          when INCR    => rx_count <= rx_count + 1;
          when HOLD    => rx_count <= rx_count;
        end case;

        -- ip_tx_start_reg processing
        case set_ip_tx_start is
          when SET  => ip_tx_start_reg <= '1';
          when CLR  => ip_tx_start_reg <= '0';
          when HOLD => ip_tx_start_reg <= ip_tx_start_reg;
        end case;

        -- pkt_count processing
        if set_pkt_cnt = '1' then
          rx_pkt_count <= rx_pkt_count + 1;
        end if;

        -- pkt_err_count processing
        if (set_pkt_type_err = '1' or set_pkt_size_err = '1') then
          rx_pkt_err_reg    <= '1';
          rx_pkt_err_count  <= rx_pkt_err_count + 1;
        elsif reset_pkt_err = '1' then
          rx_pkt_err_reg    <= '0';
          rx_pkt_err_count  <= rx_pkt_err_count; -- no change
        end if;

        -----------------------------------------------------------------
        -- Populate icmp_rx header to prepare Echo Reply response
        -----------------------------------------------------------------
        if (set_src_ip = '1') then
          icmp_rx_header.src_ip_addr  <= rx_in.hdr.src_ip_addr; -- capture src_IP address from ip_rx header
          icmp_rx_header.data_length  <= rx_in.hdr.data_length; -- capture data_length    from ip_rx header
          icmp_rx_header.msg_type     <= C_ICMP_TYPE_00;          -- Echo Reply Type 00 Code 00
          icmp_rx_header.msg_code     <= C_ICMP_CODE_00;
        end if;

        -- capture ICMP header checksum
        if (set_checksum_H = '1') then
          icmp_rx_header.checksum(15 downto 8)  <= rx_in.data.data_in;
        end if;
        if (set_checksum_L = '1') then
          icmp_rx_header.checksum(7 downto 0)   <= rx_in.data.data_in;
        end if;
        -- capture ICMP header fields :
        if (set_identifier_H = '1') then
          icmp_rx_header.identifier(15 downto 8)  <= rx_in.data.data_in;
        end if;
        if (set_identifier_L = '1') then
          icmp_rx_header.identifier(7 downto 0)   <= rx_in.data.data_in;
        end if;
        if (set_seq_number_H = '1') then
          icmp_rx_header.seq_number(15 downto 8)  <= rx_in.data.data_in;
        end if;
        if (set_seq_number_L = '1') then
          icmp_rx_header.seq_number(7 downto 0)   <= rx_in.data.data_in;
        end if;

        -- Compute ICMP Echo Reply (Ping response) checksum
        -- add 0x0800 to the Ping request checksum while recording carry-outs
        -- add the carry-outs with the resulting lower 16-bits of the checksum

        -- examples :   icmp_rx_header.checksum  :   fc68     4d55
        --              add offset (2048)         +  0800   + 0800
        --              icmp_reply_cks_full      =  10468     5555
        --              add carry-out back        +     1        0
        --              icmp_reply_checksum          0469     5555

        icmp_reply_cks_full <= std_logic_vector( resize(unsigned(icmp_rx_header.checksum),32)
                                               + resize(unsigned(icmp_checksum_offset),32) );

        --icmp_reply_checksum : take the lower 16 bits of the checkum and add all the carry-outs back
        icmp_reply_checksum <= std_logic_vector( unsigned(icmp_reply_cks_full(15 downto 0)) + unsigned( icmp_reply_cks_full(31 downto 16)) );

      end if; -- reset
    end if; -- clk
  end process rx_seq_proc;



  ------------------------------------------------------------------------------
  -- Process: rx_ram_wr_proc
  -- Description : write into memory array when receiving ICMP Echo Request data
  ------------------------------------------------------------------------------
  rx_ram_wr_proc : process(clk)
  begin
    if rising_edge(clk) then
      -- No Reset so Vivado synthesis tool can infer Distributed RAM
      if rx_state = USER_DATA then
        icmp_rx_data_array(to_integer(rx_count)) <= rx_in.data.data_in;
      end if;
    end if;
  end process rx_ram_wr_proc;

  ------------------------------------------------------------------------------
  -- Process: rx_ram_rd_proc
  -- Description : read into memory array when sending Echo Reply data
  ------------------------------------------------------------------------------
  rx_ram_rd_proc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        tx_data_out   <= x"00";
        tx_data_valid <= '0';
        tx_data_last  <= '0';
      else
        tx_data_last  <= '0'; -- default value
        tx_data_valid <= '0'; -- default value

        -- ICMP Echo Reply : read rx_data_array when ip_tx is ready to accept data
        if ip_tx_data_out_ready = '1' then

          case tx_state is
            when SEND_ICMP_HEADER =>
              tx_data_valid <= '1';
              case tx_count is
                when x"0000" => tx_data_out <= C_ICMP_TYPE_00; -- Echo Reply Type 00 Code 00
                when x"0001" => tx_data_out <= C_ICMP_CODE_00;
                when x"0002" => tx_data_out <= icmp_reply_checksum(15 downto 8);
                when x"0003" => tx_data_out <= icmp_reply_checksum( 7 downto 0);
                when x"0004" => tx_data_out <= icmp_rx_header.identifier(15 downto 8);
                when x"0005" => tx_data_out <= icmp_rx_header.identifier( 7 downto 0);
                when x"0006" => tx_data_out <= icmp_rx_header.seq_number(15 downto 8);
                when x"0007" => tx_data_out <= icmp_rx_header.seq_number( 7 downto 0);
                                -- ping with 0 bytes of data
                                if (rx_data_length = 0) then
                                  tx_data_last <= '1';
                                end if;

                when others =>
                  -- shouldnt get here - handle as error
              end case;

            when SEND_USER_DATA =>
              tx_data_valid <= '1';
              tx_data_out <= icmp_rx_data_array(to_integer(tx_count)); --read rx memory array
              if tx_count = unsigned(rx_data_length) then
                tx_data_last <= '1';
              end if;
            when others =>
          end case;
        else -- ip_tx_data_out_ready = 0
          tx_data_valid <= '0';
        end if;

      end if; -- reset
    end if; -- clk
  end process rx_ram_rd_proc;

  -----------------------
  -- IP_TX data output --
  -----------------------
  ip_tx_data.data_out       <= tx_data_out;
  ip_tx_data.data_out_valid <= tx_data_valid;
  ip_tx_data.data_out_last  <= tx_data_last;


  -- ***************************************************************************
  --                          ICMP Tx part
  -- ***************************************************************************
  icmp_echo_reply <= icmp_echo_request;

  ------------------------------------------------------------------------------
  -- Process: tx_comb_proc
  -- TX combinatorial process to implement FSM and determine control signals
  ------------------------------------------------------------------------------
  tx_comb_proc : process (
    -- input signals
    icmp_echo_reply, icmp_rx_header, ip_tx_result, ip_tx_data_out_ready,
    -- state variables
    tx_state, tx_count, ip_tx_start_reg,
    -- control signals
    next_tx_state, set_tx_state, tx_count_mode,
    rx_data_length, set_ip_tx_start
    )
    begin
      -- set signal defaults
      next_tx_state       <= IDLE;    -- prevent from infering a latch
      set_tx_state        <= '0';
      tx_count_mode       <= HOLD;
      set_ip_tx_start     <= HOLD;

      -- TX_FSM combinatorial
      case tx_state is
      -----------------
      -- IDLE
      -----------------
      when IDLE =>

        tx_count_mode <= RST;

        -- wait until we have received en ICMP Echo Request (ping)
        if icmp_echo_reply = '1' then
            -- start to send UDP header
            next_tx_state   <= PAUSE;
            set_tx_state    <= '1';
            set_ip_tx_start <= SET;   -- rise ip_tx_start
        end if;

      -----------------
      -- PAUSE
      -----------------
      when PAUSE =>
        -- delay one clock for IP layer to respond to ip_tx_start and remove any tx error result

        if ip_tx_data_out_ready = '1' then
          next_tx_state <= SEND_ICMP_HEADER;
          set_tx_state <= '1';
        end if;

      ---------------------
      -- SEND ICMP HEADER
      ---------------------
      when SEND_ICMP_HEADER =>

        if ip_tx_result = IPTX_RESULT_ERR then        -- 0x10
          set_ip_tx_start <= CLR;    -- reset ip_tx_start
          next_tx_state   <= IDLE;
          set_tx_state    <= '1';
        else
          -- wait until ip tx is ready to accept data
          if ip_tx_data_out_ready = '1' then

            if tx_count = to_unsigned(C_ICMP_HEADER_LENGTH-1,16) then       -- 7

              -- ping with 0 bytes of data : TX terminated normally
              if (rx_data_length = 0) then
                tx_count_mode     <= RST;     -- reset tx_count
                next_tx_state     <= IDLE;
                set_tx_state      <= '1';
                set_ip_tx_start   <= CLR;     -- reset ip_tx_start
              else
                tx_count_mode <= SET_VAL;  -- -- tx_count restarts at 1
                next_tx_state <= SEND_USER_DATA;
                set_tx_state  <= '1';
              end if;
            else
              tx_count_mode <= INCR;
              next_tx_state <= SEND_ICMP_HEADER;
            end if;

          else
            -- IP Tx not ready to accept data
            next_tx_state <= SEND_ICMP_HEADER;
            tx_count_mode <= HOLD;
          end if;
        end if; -- ip_tx_result

      ---------------------
      -- SEND USER DATA
      ---------------------
      when SEND_USER_DATA =>      -- Send the same as Echo Request input frame

        -- In this state tx_count counts from 1 to rx_data_length

        -- wait until ip tx is ready to accept data
        if ip_tx_data_out_ready = '1' then

          if tx_count = unsigned(rx_data_length) then
            -- TX terminated due to count - end normally
            tx_count_mode         <= RST;
            next_tx_state         <= IDLE;
            set_tx_state          <= '1';
            set_ip_tx_start       <= CLR;
          else
            -- TX continues
            tx_count_mode   <= INCR;
            next_tx_state   <= SEND_USER_DATA;
          end if;

        else
          -- IP Tx not ready to accept data
          next_tx_state <= SEND_USER_DATA;
          tx_count_mode <= HOLD;
        end if;

      end case; -- tx_state
  end process tx_comb_proc;


  -----------------------------------------------------------------------------------
  -- Process: tx_seq_proc
  -- TX sequential process to action control signals and change states and outputs
  -----------------------------------------------------------------------------------
  tx_seq_proc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- reset state variables
        tx_state        <= IDLE;
        tx_count        <= (others=>'0');
        ip_tx_start_reg <= '0';
        ip_tx_header    <= C_IPV4_TX_HEADER_NULL;

      else
        -- Next tx_state processing
        if set_tx_state = '1' then
          tx_state <= next_tx_state;
        else
          tx_state <= tx_state;
        end if;
        -- tx_count processing
        case tx_count_mode is
          when RST     => tx_count <= x"0000";
          when SET_VAL => tx_count <= x"0001";
          when INCR    => tx_count <= tx_count + 1;
          when HOLD    => tx_count <= tx_count;     -- no change
        end case;
        -- ip_tx_start_reg processing
        case set_ip_tx_start is
          when SET  => ip_tx_start_reg <= '1';
          when CLR  => ip_tx_start_reg <= '0';
          when HOLD => ip_tx_start_reg <= ip_tx_start_reg; -- no change
        end case;
        -------------------------
        -- IP_TX header output --
        -------------------------
        if icmp_echo_reply = '1' then
          ip_tx_header.protocol      <= C_ICMP_PROTOCOL;  -- x"01"
          ip_tx_header.data_length   <= icmp_rx_header.data_length;
          ip_tx_header.dst_ip_addr   <= icmp_rx_header.src_ip_addr;
        end if;

      end if; -- reset
    end if; -- clk
  end process tx_seq_proc;

  ----------------------------------------
  -- outputs followers assignements
  --------------------------------------
  ip_tx_start         <= ip_tx_start_reg;
  ip_tx.hdr           <= ip_tx_header;
  ip_tx.data          <= ip_tx_data;

  icmp_pkt_count      <= std_logic_vector(rx_pkt_count);
  icmp_pkt_err_count  <= std_logic_vector(rx_pkt_err_count);
  icmp_pkt_err        <= rx_pkt_err_reg;


end behavioral;
--==============================================================================
-- End of Code
--==============================================================================

