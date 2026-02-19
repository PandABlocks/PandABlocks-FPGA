

-- Test with endat_slave and endat2_sniffer.
-- Generate 46 clocks
--    C_CMD_BITS (10) + C_TURN_BITS (4) + START(1) + F1(1) + POSITION(25) + C_CRC_BITS (5)
--


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity endat2_master is
  generic (
    g_rx_falling_edge : integer := 1  -- 1: sample RX on SCK falling edge (default), 0: rising edge
  );
  port (
    clk_i          : in  std_logic;
    reset_i        : in  std_logic;

    -- Configuration
    BITS           : in  std_logic_vector(7 downto 0);   -- position bits (typically 25)
    CLK_PERIOD_i   : in  std_logic_vector(31 downto 0);  -- SCK half-period control
    FRAME_PERIOD_i : in  std_logic_vector(31 downto 0);  -- frame rate divider

    -- Status / data
    link_up_o      : out std_logic;
    health_o       : out std_logic_vector(31 downto 0);
    posn_o         : out std_logic_vector(31 downto 0);
    posn_valid_o   : out std_logic;

    -- Debug: commanded word as actually driven on the bus
    cmd_o          : out std_logic_vector(9 downto 0);
    cmd_valid_o    : out std_logic;

    -- Physical EnDat interface
    endat_sck_o    : out std_logic;
    endat_dat_i    : in  std_logic;
    endat_dat_o    : out std_logic
  );
end endat2_master;

architecture rtl of endat2_master is


  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant C_CMD_BITS  : integer := 10;
  constant C_TURN_BITS : integer := 4;
  constant C_CRC_BITS  : integer := 5;

  -- Required EnDat command (placeholder used in your previous version)
  constant C_MODE_COMMAND : std_logic_vector(9 downto 0) := "0000011100";

  -----------------------------------------------------------------------------
  -- Frame trigger + clock generator
  -----------------------------------------------------------------------------
  signal frame_cnt_r     : unsigned(31 downto 0) := (others => '0');
  signal frame_start_p   : std_logic := '0';

  signal n_clks_r        : std_logic_vector(7 downto 0) := (others => '0');

  signal clkgen_active   : std_logic := '0';
  signal clkgen_busy     : std_logic := '0';
  signal endat_sck_r     : std_logic := '1';

  -----------------------------------------------------------------------------
  -- SCK edge detect
  -----------------------------------------------------------------------------
  signal endat_sck_d1    : std_logic := '1';
  signal sck_rise        : std_logic := '0';
  signal sck_fall        : std_logic := '0';

  -----------------------------------------------------------------------------
  -- Bit index counter (counts SCK rising edges)
  -----------------------------------------------------------------------------
  signal bit_idx_r       : unsigned(7 downto 0) := (others => '0');

  -----------------------------------------------------------------------------
  -- Timeout support
  -----------------------------------------------------------------------------
  -- Count actual SCK rising edges observed during the frame.
  signal sck_rise_cnt_r  : unsigned(7 downto 0) := (others => '0');

  -- Timeout flags:
  --  - sck_cnt_err_r: wrong number of SCKs in frame (generated vs expected)
  --  - start_timeout_r: START bit not observed within 20 SCK bit-times after CMD
  signal sck_cnt_err_r   : std_logic := '0';
  signal start_seen_r    : std_logic := '0';
  signal start_timeout_r : std_logic := '0';

  -----------------------------------------------------------------------------
  -- Command capture (debug)
  -----------------------------------------------------------------------------
  signal cmd_tx_r       : std_logic_vector(9 downto 0) := (others => '0');
  signal cmd_reg_r      : std_logic_vector(9 downto 0) := (others => '0');
  signal cmd_valid_r    : std_logic := '0';

  -----------------------------------------------------------------------------
  -- Captured fields
  -----------------------------------------------------------------------------
  signal s_bit_r         : std_logic := '0';
  signal f1_bit_r        : std_logic := '0';

  signal posn_r          : std_logic_vector(31 downto 0) := (others => '0');
  signal rx_crc_r        : std_logic_vector(4 downto 0)  := (others => '0');
  signal calc_crc_r      : std_logic_vector(4 downto 0)  := (others => '0');
  signal crc_err_r       : std_logic := '0';

  signal posn_valid_r    : std_logic := '0';
  signal link_up_r       : std_logic := '0';
  signal frame_done_r    : std_logic := '0';

  -----------------------------------------------------------------------------
  -- CRC FFs (same structure as endat_slave.vhd)
  -----------------------------------------------------------------------------
  signal FF0             : std_logic := '1';
  signal FF1             : std_logic := '1';
  signal FF2             : std_logic := '1';
  signal FF3             : std_logic := '1';
  signal FF4             : std_logic := '1';
  signal S_en            : std_logic := '0';

  signal bits_i_r        : integer range 0 to 255 := 25;
  signal rx_fall_en_r    : std_logic := '1';

  ----------------------------------------------------------------------------
  -- Vivado ILA Debug Attributes
  ----------------------------------------------------------------------------
  attribute mark_debug : string;

  attribute mark_debug of frame_cnt_r      : signal is "true";
  attribute mark_debug of bit_idx_r        : signal is "true";
  attribute mark_debug of sck_rise_cnt_r   : signal is "true";
  attribute mark_debug of sck_cnt_err_r    : signal is "true";
  attribute mark_debug of start_timeout_r  : signal is "true";
  attribute mark_debug of start_seen_r     : signal is "true";
  attribute mark_debug of rx_crc_r         : signal is "true";
  attribute mark_debug of calc_crc_r       : signal is "true";
  attribute mark_debug of crc_err_r        : signal is "true";
  attribute mark_debug of cmd_reg_r        : signal is "true";
  attribute mark_debug of cmd_valid_r      : signal is "true";

begin

  endat_sck_o  <= endat_sck_r;
  posn_o       <= posn_r;
  posn_valid_o <= posn_valid_r;
  link_up_o    <= link_up_r;

  cmd_o        <= cmd_reg_r;
  cmd_valid_o  <= cmd_valid_r;

  -----------------------------------------------------------------------------
  -- Frame start trigger (simple counter)
  -----------------------------------------------------------------------------
  p_frame_trig : process(clk_i)
    variable frame_period_u : unsigned(31 downto 0);
  begin
    if rising_edge(clk_i) then
      if reset_i = '1' then
        frame_cnt_r   <= (others => '0');
        frame_start_p <= '0';
      else
        frame_start_p <= '0';
        frame_period_u := unsigned(FRAME_PERIOD_i);

        if frame_period_u = 0 then
          frame_start_p <= '1';
        else
          if frame_cnt_r = frame_period_u then
            frame_cnt_r   <= (others => '0');
            frame_start_p <= '1';
          else
            frame_cnt_r <= frame_cnt_r + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Compute N (total clocks - 1) at each frame start
  -----------------------------------------------------------------------------
  p_frame_len : process(clk_i)
    variable total_clks : integer;
    variable bits_i     : integer;
  begin
    if rising_edge(clk_i) then
      if reset_i = '1' then
        n_clks_r     <= (others => '0');
        bits_i_r     <= 25;
        rx_fall_en_r <= '1';
      else
        if frame_start_p = '1' then
          bits_i := to_integer(unsigned(BITS));
          if bits_i < 1 then
            bits_i := 1;
          elsif bits_i > 32 then
            bits_i := 32;
          end if;
          bits_i_r <= bits_i;

          if g_rx_falling_edge /= 0 then
            rx_fall_en_r <= '1';
          else
            rx_fall_en_r <= '0';
          end if;

          -- +1 dummy STOP clock to ensure last CRC bit is never truncated
          total_clks := C_CMD_BITS + C_TURN_BITS + 1 + 1 + bits_i + C_CRC_BITS + 1;
          n_clks_r <= std_logic_vector(to_unsigned(total_clks - 1, 8));
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Clock generator instance
  -----------------------------------------------------------------------------
  u_clkgen : entity work.endat_clock_gen
  generic map (
    DEAD_PERIOD     => (20000/8)   
            )
  port map (
      clk_i         => clk_i,
      reset_i       => reset_i,
      N             => n_clks_r,
      CLK_PERIOD    => CLK_PERIOD_i,
      start_i       => frame_start_p,
      enable_cnt_i  => '1',
      clock_pulse_o => endat_sck_r,
      active_o      => clkgen_active,
      busy_o        => clkgen_busy
    );

  -----------------------------------------------------------------------------
  -- Edge detect on generated SCK
  -----------------------------------------------------------------------------
  p_sck_edge : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if reset_i = '1' then
        endat_sck_d1 <= '1';
        sck_rise     <= '0';
        sck_fall     <= '0';
      else
        endat_sck_d1 <= endat_sck_r;
        sck_rise     <= (not endat_sck_d1) and endat_sck_r;
        sck_fall     <= endat_sck_d1 and (not endat_sck_r);
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Main TX/RX
  -----------------------------------------------------------------------------
  p_txrx : process(clk_i)
    -- indices counted in "bit time" units (based on SCK rising edge count)
    variable sample_idx     : integer;
    variable base_start_idx : integer;
    variable recv_start_idx : integer;
    variable pos_start_idx  : integer;
    variable crc_start_idx  : integer;
    variable bits_i         : integer;

    variable crc_count      : integer;
    variable exp_crc_bit    : std_logic;

    -- CRC intermediate (same as endat_slave.vhd)
    variable cs1_v          : std_logic;
    variable cs2_v          : std_logic;

    variable rx_bit         : std_logic;

    variable expected_rises : unsigned(7 downto 0);
  begin
    if rising_edge(clk_i) then
      if reset_i = '1' then
        bit_idx_r       <= (others => '0');
        sck_rise_cnt_r  <= (others => '0');

        sck_cnt_err_r   <= '0';
        start_seen_r    <= '0';
        start_timeout_r <= '0';

        endat_dat_o     <= '1';

        posn_r          <= (others => '0');
        rx_crc_r        <= (others => '0');
        calc_crc_r      <= (others => '0');
        crc_err_r       <= '0';

        s_bit_r         <= '0';
        f1_bit_r        <= '0';

        posn_valid_r    <= '0';
        link_up_r       <= '0';
        frame_done_r    <= '0';

        cmd_tx_r        <= (others => '0');
        cmd_reg_r       <= (others => '0');
        cmd_valid_r     <= '0';

        FF0             <= '1';
        FF1             <= '1';
        FF2             <= '1';
        FF3             <= '1';
        FF4             <= '1';
        S_en            <= '0';

      else
        posn_valid_r <= '0';

        -- Preset per new frame
        if frame_start_p = '1' then
          bit_idx_r       <= (others => '0');
          sck_rise_cnt_r  <= (others => '0');

          sck_cnt_err_r   <= '0';
          start_seen_r    <= '0';
          start_timeout_r <= '0';

          -- Present first CMD bit (updated again on first SCK falling edge)
          endat_dat_o     <= C_MODE_COMMAND(9);

          posn_r          <= (others => '0');
          rx_crc_r        <= (others => '0');
          calc_crc_r      <= (others => '0');
          crc_err_r       <= '0';

          s_bit_r         <= '0';
          f1_bit_r        <= '0';

          frame_done_r    <= '0';

          cmd_tx_r        <= (others => '0');
          cmd_valid_r     <= '0';

          -- CRC init (seed again at START bit)
          FF0             <= '1';
          FF1             <= '1';
          FF2             <= '1';
          FF3             <= '1';
          FF4             <= '1';
          S_en            <= '0';
        end if;

        -----------------------------------------------------------------------
        -- TX: update output on SCK falling edges (stable for next rising edge)
        -----------------------------------------------------------------------
        if (clkgen_active = '1') and (sck_fall = '1') then
          if to_integer(bit_idx_r) < C_CMD_BITS then
            -- Drive CMD bit (MSB-first) and capture it into a debug register.
            endat_dat_o <= C_MODE_COMMAND(9 - to_integer(bit_idx_r));
            cmd_tx_r(9 - to_integer(bit_idx_r)) <= C_MODE_COMMAND(9 - to_integer(bit_idx_r));

            -- When the last CMD bit has just been driven, latch the full word.
            if to_integer(bit_idx_r) = (C_CMD_BITS - 1) then
              cmd_reg_r    <= cmd_tx_r;
              cmd_reg_r(0) <= C_MODE_COMMAND(0);  -- ensure last-assigned bit is included in same cycle
              cmd_valid_r  <= '1';
            end if;
          else
            -- Release line (high) after CMD
            endat_dat_o <= '1';
          end if;
        end if;

        -----------------------------------------------------------------------
        -- Advance bit index + count actual SCK rising edges
        -----------------------------------------------------------------------
        if (clkgen_active = '1') and (sck_rise = '1') then
          bit_idx_r      <= bit_idx_r + 1;
          sck_rise_cnt_r <= sck_rise_cnt_r + 1;
        end if;

        -----------------------------------------------------------------------
        -- RX sampling + START timeout check
        -----------------------------------------------------------------------
        if (clkgen_active = '1') then
          if (rx_fall_en_r = '1' and sck_fall = '1') or (rx_fall_en_r = '0' and sck_rise = '1') then

            bits_i := bits_i_r;

            -- Base START index in "rising-edge bit times" is CMD+TURN (=14).
            base_start_idx := C_CMD_BITS + C_TURN_BITS;

            if rx_fall_en_r = '1' then
              -- Falling samples after the rising edge, so use current bit_idx_r
              sample_idx := to_integer(bit_idx_r);

              -- Shift all phase indices by +1 for FALL sampling
              recv_start_idx := base_start_idx + 1;   -- START(S)
            else
              sample_idx := to_integer(bit_idx_r);
              recv_start_idx := base_start_idx;       -- START(S)
            end if;

            pos_start_idx := recv_start_idx + 1 + 1;  -- S + F1 (F2 bypass)
            crc_start_idx := pos_start_idx + bits_i;  -- after position bits

            rx_bit := endat_dat_i;

            -------------------------------------------------------------------
            -- Timeout #2: After CMD, if START is not observed within 20 SCKs,
            -- flag timeout.
            --
            -- Definition used here:
            --   "After sending CMD" -> after CMD(10) bits are done.
            -- The check is performed in sample_idx (bit-time index).
            -------------------------------------------------------------------
            if (start_seen_r = '0') then
              if sample_idx >= (C_CMD_BITS + 20) then
                start_timeout_r <= '1';
              end if;
            end if;

            -- START bit: seed CRC FFs and enable accumulation
            if sample_idx = recv_start_idx then
              s_bit_r <= rx_bit;

              -- START must be '1' for a valid reply
              if rx_bit = '1' then
                start_seen_r <= '1';
              end if;

              FF0  <= '1';
              FF1  <= '1';
              FF2  <= '1';
              FF3  <= '1';
              FF4  <= '1';
              S_en <= '1';

            -- F1 bit (included in CRC)
            elsif sample_idx = (recv_start_idx + 1) then
              f1_bit_r <= rx_bit;

              cs1_v := (FF4 and S_en) xor (rx_bit and S_en);
              cs2_v := cs1_v and S_en;
              FF0 <= cs1_v;
              FF1 <= FF0 xor cs2_v;
              FF2 <= FF1;
              FF3 <= FF2 xor cs2_v;
              FF4 <= FF3;

            -- Position bits (LSB-first into posn_r, included in CRC)
            elsif (sample_idx >= pos_start_idx) and (sample_idx < (pos_start_idx + bits_i)) then
              posn_r(sample_idx - pos_start_idx) <= rx_bit;

              cs1_v := (FF4 and S_en) xor (rx_bit and S_en);
              cs2_v := cs1_v and S_en;
              FF0 <= cs1_v;
              FF1 <= FF0 xor cs2_v;
              FF2 <= FF1;
              FF3 <= FF2 xor cs2_v;
              FF4 <= FF3;

              -- When last position bit captured, drop S_en for CRC serialization
              if sample_idx = (pos_start_idx + bits_i - 1) then
                S_en <= '0';
              end if;

            -- CRC bits: compare to expected (not FF4), store both for monitoring
            elsif (sample_idx >= crc_start_idx) and (sample_idx < (crc_start_idx + C_CRC_BITS)) then
              crc_count   := sample_idx - crc_start_idx; -- 0..4
              exp_crc_bit := not FF4;

              -- Store MSB-first (first CRC bit goes to bit[4])
              rx_crc_r(4 - crc_count)   <= rx_bit;
              calc_crc_r(4 - crc_count) <= exp_crc_bit;

              if rx_bit /= exp_crc_bit then
                crc_err_r <= '1';
              end if;

              -- Advance FFs like slave ENDAT_CRC (S_en=0 => shift zeros)
              cs1_v := (FF4 and S_en) xor (rx_bit and S_en);
              cs2_v := cs1_v and S_en;
              FF0 <= cs1_v;
              FF1 <= FF0 xor cs2_v;
              FF2 <= FF1;
              FF3 <= FF2 xor cs2_v;
              FF4 <= FF3;

            else
              null;
            end if;

          end if;
        end if;

        -----------------------------------------------------------------------
        -- Frame end detect + timeout checks
        -----------------------------------------------------------------------
        if (clkgen_active = '0') and (clkgen_busy = '1') then
          if frame_done_r = '0' then
            frame_done_r <= '1';

            -- Expected rising edges == generated clocks == N+1
            expected_rises := unsigned(n_clks_r) + 1;

            if (sck_rise_cnt_r /= expected_rises) or (start_timeout_r = '1') then
              sck_cnt_err_r <= '1';
              link_up_r     <= '0';
              -- posn_valid_r stays '0' on timeout
            else
              sck_cnt_err_r <= '0';
              posn_valid_r  <= '1';
              link_up_r     <= '1';
            end if;
          end if;
        end if;

        if clkgen_busy = '0' then
          frame_done_r <= '0';
        end if;

      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Health output (status code)
  -----------------------------------------------------------------------------
  p_health : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if reset_i = '1' then
        health_o <= (others => '0');
      else
        -- Priority: timeout(1) > protocol(4) > OK(0)
        if (sck_cnt_err_r = '1') or (start_timeout_r = '1') then
          health_o <= std_logic_vector(to_unsigned(1, 32));
        elsif crc_err_r = '1' then
          health_o <= std_logic_vector(to_unsigned(4, 32));
        else
          health_o <= std_logic_vector(to_unsigned(0, 32));
        end if;
      end if;
    end if;
  end process;

end rtl;

