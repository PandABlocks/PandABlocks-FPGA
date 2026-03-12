
-- Test model: 
-- HEIDENHAIN ECN 425 2048
--   EnDat22
--   Singleturn 25bit(33,554,432 pos/rev
--   F2 error 2 (only with EnDat 2.2 commands)
--
--


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- endat2_sniffer.vhd
--
-- EnDat sniffer (position + CRC) for streams like:
--   CMD(10) -> START(1) -> F1(1) -> DATA(N bits, typically 25, LSB-first) -> CRC(5)
--
-- CRC is computed AFTER capturing the position word, using external module:
--   work.endat_crc5_vec
--
-- CRC is computed over DATA bits only (START/F1/F2 excluded).
--
-- CMD sampling mitigation:
-- - CMD advances on sck_edge_cmd (optionally forced to rising edge)
-- - CMD data is snapshotted at sck_edge_cmd into dat_edge_cmd_r (with dat_ff1==dat_ff2 guard)
--
-- Monitoring:
-- - cmd_o/cmd_valid_o: latched when posn_valid_r is asserted (frame commit point)
-- - posn_o: position output (after encoding conversion)
-- - crc_rx_o: received CRC bits from stream
-- - crc_calc_o: calculated CRC from position bits


entity endat2_sniffer is
  generic (
    G_ENDAT2_2        : natural   := 0;
    DATA_INVERT       : std_logic := '0';
    SAMPLE_FALL       : std_logic := '1';   -- use 1 for ECN 425 2048
    IDLE_GAP_CLKS     : natural   := 200;
    CRC_BYPASS        : natural   := 0;
    FRAME_STALE_CLKS  : natural    := 0;
    -- 1 = normal (F1+F2), 0 = bypass F2 (only F1 present in stream)
    F2_PRESENT        : natural := 0; -- Only EnDat 2.2 commands
    -- 1 = check command == C_CMD_POS, 0 = bypass command compare (accept any command)
    CMD_CHECK_EN      : natural := 0;
    -- 1 = sample CMD(10) on SCK rising edge regardless of SAMPLE_FALL,
    -- 0 = CMD uses the same selected edge as the rest of the frame.
    CMD_BRISING_EDGE  : natural := 1;
    -- CRC bit order when computing CRC from captured position bits:
    -- 0 = LSB-first (data bit0 -> bitN-1), 1 = MSB-first (bitN-1 -> bit0)
    CRC_MSB_FIRST     : natural := 0
  );
  port (
    clk_i          : in  std_logic;
    reset_i        : in  std_logic;

    -- Configuration interface
    ENCODING       : in  std_logic_vector(1 downto 0);  -- 0 Unsigned Binary, 1 Unsigned Gray, 2 Signed Binary, 3 Signed Gray
    BITS           : in  std_logic_vector(7 downto 0);  -- Position bits (1..32)

    link_up_o      : out std_logic;
    health_o       : out std_logic_vector(31 downto 0);
    error_o        : out std_logic;

    -- Physical ENDat interface
    endat_sck_i    : in  std_logic;
    endat_dat_i    : in  std_logic;

    -- Block outputs
    posn_o         : out std_logic_vector(31 downto 0);

    --
    -- Debug outputs : Not needed for the Panda block interface
    -- external monitoring of CMD latched at posn_valid
    cmd_o          : out std_logic_vector(9 downto 0);
    cmd_valid_o    : out std_logic;    
    crc_rx_o       : out std_logic_vector(4 downto 0);   -- CRC received from encoder
    crc_calc_o     : out std_logic_vector(4 downto 0);   -- CRC calculation result
    error_count_o  : out std_logic_vector(31 downto 0);  -- CRC error counts
    posn_valid_o   : out std_logic;                      -- 1clk pulse when posn_o updated
    frame_ok_o     : out std_logic;                      -- same as posn_valid_o
    sample_count_o : out std_logic_vector(31 downto 0)   -- increments on each posn_valid_o
  );
end entity;


architecture rtl of endat2_sniffer is

  constant C_MODE_BITS : natural := 10;
  constant C_CRC_BITS  : natural := 5;
  constant C_SEEK_START_TIMEOUT : natural := 255;

  -- Position read command (10-bit)
  constant C_CMD_POS : std_logic_vector(9 downto 0) := "0000011100"; -- 0x1C

  type t_state is (
    ST_SYNC,
    ST_CMD,
    ST_SEEK_START,
    ST_F1,
    ST_F2,
    ST_POS,
    ST_CRC_RX,
    ST_CRC_CALC
  );

  signal st, st_n : t_state := ST_SYNC;

  -- Synchronize SCK/DAT into clk_i domain
  signal sck_ff1, sck_ff2 : std_logic := '0';
  signal dat_ff1, dat_ff2 : std_logic := '0';
  signal sck_edge_any     : std_logic := '0';

  -- Selected edges:
  signal sck_edge_gen     : std_logic := '0';  -- general edge (SAMPLE_FALL based)
  signal sck_edge_cmd     : std_logic := '0';  -- CMD edge (optional rising-only)

  -- DATA snapshot at selected SCK edge
  signal dat_edge_r       : std_logic := '0';

  -- CMD DATA snapshot at CMD edge
  signal dat_edge_cmd_r   : std_logic := '0';

  -- Idle gap timer (clk_i domain)
  signal idle_cnt, idle_cnt_n : unsigned(15 downto 0) := (others => '0');
  signal gap_seen, gap_seen_n : std_logic := '0';

  -- Counters
  signal cmd_idx,  cmd_idx_n  : unsigned(3 downto 0) := (others => '0');
  signal pos_idx,  pos_idx_n  : unsigned(7 downto 0) := (others => '0');
  signal crc_rx_idx, crc_rx_idx_n : unsigned(2 downto 0) := (others => '0');
  signal seek_cnt, seek_cnt_n : unsigned(7 downto 0) := (others => '0');

  -- Total SCK selected-edge count per frame (8-bit)
  signal sclk_cnt, sclk_cnt_n : unsigned(7 downto 0) := (others => '0');

  -- 32-bit error counter (counts failed frames/events; latched => max +1 per frame)
  signal error_count, error_count_n : unsigned(31 downto 0) := (others => '0');

  -- Latch to ensure one increment per frame
  signal frame_error_lat, frame_error_lat_n : std_logic := '0';

  -- Flyscan sample counter
  signal sample_count, sample_count_n : unsigned(31 downto 0) := (others => '0');

  -- 1clk pulse when we commit a good frame (position updated)
  signal posn_valid_r, posn_valid_r_n : std_logic := '0';

  -- Age counter since last successful commit (clk_i cycles)
  signal frame_age_cnt, frame_age_cnt_n : unsigned(31 downto 0) := (others => '0');

  -- Config bits clamped to 1..32
  signal bits_u    : unsigned(7 downto 0);
  signal bits_clip : unsigned(7 downto 0);

  -- Captured fields
  signal cmd_r, cmd_r_n       : std_logic_vector(C_MODE_BITS-1 downto 0) := (others => '0');

  -- pos_work is filled LSB-first from the serial stream: pos_work(0) is first received data bit.
  signal pos_work, pos_work_n : std_logic_vector(31 downto 0) := (others => '0');
  signal pos_out,  pos_out_n  : std_logic_vector(31 downto 0) := (others => '0');

  -- Received CRC bits (captured from serial stream, MSB-first within the 5-bit field)
  signal rx_crc_r, rx_crc_r_n : std_logic_vector(4 downto 0) := (others => '0');

  -- CRC module handshake
  signal crc_start_r, crc_start_r_n : std_logic := '0';
  signal crc_busy    : std_logic := '0';
  signal crc_done    : std_logic := '0';
  signal crc_calc    : std_logic_vector(4 downto 0) := (others => '0');
  signal crc_msb_first_s : std_logic := '0';

  -- Debug mirror
  signal cmd_data : std_logic_vector(9 downto 0) := (others => '0');

  -- Status
  signal link_up_r, link_up_r_n : std_logic := '0';
  signal err_r, err_r_n         : std_logic := '0';

  -- Health sticky bits (cleared at frame start)
  signal f1_r, f1_r_n                   : std_logic := '0';
  signal f2_r, f2_r_n                   : std_logic := '0';
  signal timeout_err_r, timeout_err_r_n : std_logic := '0';
  signal crc_err_r, crc_err_r_n         : std_logic := '0';

  ----------------------------------------------------------------------------
  -- NEW: CMD latch at posn_valid
  ----------------------------------------------------------------------------
  signal cmd_lat_r, cmd_lat_r_n       : std_logic_vector(9 downto 0) := (others => '0');
  signal cmd_valid_r, cmd_valid_r_n   : std_logic := '0';

  ----------------------------------------------------------------------------
  -- Output encoding conversion (VHDL-2001 compatible)
  ----------------------------------------------------------------------------
  signal posn_enc : std_logic_vector(31 downto 0) := (others => '0');

  -- Gray -> Binary converter (MSB-first Gray code)
  function gray_to_bin(g : std_logic_vector) return std_logic_vector is
    variable b : std_logic_vector(g'range);
  begin
    b(b'high) := g(g'high);
    for i in b'high-1 downto b'low loop
      b(i) := b(i+1) xor g(i);
    end loop;
    return b;
  end function;

  function clamp_1_32(x : unsigned(7 downto 0)) return unsigned is
  begin
    if x = 0 then
      return to_unsigned(1, 8);
    elsif x > to_unsigned(32, 8) then
      return to_unsigned(32, 8);
    else
      return x;
    end if;
  end function;

  ----------------------------------------------------------------------------
  -- Vivado ILA Debug Attributes
  ----------------------------------------------------------------------------
--  attribute mark_debug : string;

--  attribute mark_debug of st              : signal is "true";
--  attribute mark_debug of sck_ff2         : signal is "true";
--  attribute mark_debug of dat_ff1         : signal is "true";
--  attribute mark_debug of dat_ff2         : signal is "true";
--  attribute mark_debug of dat_edge_r      : signal is "true";
--  attribute mark_debug of dat_edge_cmd_r  : signal is "true";
--  attribute mark_debug of sck_edge_gen    : signal is "true";
--  attribute mark_debug of sck_edge_cmd    : signal is "true";
--  attribute mark_debug of sck_edge_any    : signal is "true";

--  attribute mark_debug of idle_cnt        : signal is "true";
--  attribute mark_debug of gap_seen        : signal is "true";
--  attribute mark_debug of cmd_idx         : signal is "true";
--  attribute mark_debug of pos_idx         : signal is "true";
--  attribute mark_debug of crc_rx_idx      : signal is "true";
--  attribute mark_debug of seek_cnt        : signal is "true";
--  attribute mark_debug of sclk_cnt        : signal is "true";

--  attribute mark_debug of error_count     : signal is "true";
--  attribute mark_debug of frame_error_lat : signal is "true";

--  attribute mark_debug of sample_count    : signal is "true";
--  attribute mark_debug of posn_valid_r    : signal is "true";
--  attribute mark_debug of frame_age_cnt   : signal is "true";

--  attribute mark_debug of cmd_r           : signal is "true";
--  attribute mark_debug of cmd_data        : signal is "true";
--  attribute mark_debug of pos_work        : signal is "true";
--  attribute mark_debug of pos_out         : signal is "true";
--  attribute mark_debug of rx_crc_r        : signal is "true";

--  attribute mark_debug of link_up_r       : signal is "true";
--  attribute mark_debug of err_r           : signal is "true";

--  attribute mark_debug of crc_start_r     : signal is "true";
--  attribute mark_debug of crc_busy        : signal is "true";
--  attribute mark_debug of crc_done        : signal is "true";
--  attribute mark_debug of crc_calc        : signal is "true";
--  attribute mark_debug of crc_msb_first_s : signal is "true";

--  attribute mark_debug of f1_r            : signal is "true";
--  attribute mark_debug of f2_r            : signal is "true";
--  attribute mark_debug of timeout_err_r   : signal is "true";
--  attribute mark_debug of crc_err_r       : signal is "true";

--  attribute mark_debug of cmd_lat_r       : signal is "true";
--  attribute mark_debug of cmd_valid_r     : signal is "true";



begin
  bits_u    <= unsigned(BITS);
  bits_clip <= clamp_1_32(bits_u);

  cmd_data <= cmd_r;

  -- CRC order select (VHDL-2001 friendly)
  crc_msb_first_s <= '1' when (CRC_MSB_FIRST /= 0) else '0';

  -- Outputs
  posn_o         <= posn_enc;
  link_up_o      <= link_up_r;
  error_o        <= err_r;

  -- External monitoring
  cmd_o          <= cmd_lat_r;
  cmd_valid_o    <= cmd_valid_r;

  crc_rx_o       <= rx_crc_r;
  crc_calc_o     <= crc_calc;

  error_count_o  <= std_logic_vector(error_count);

  posn_valid_o   <= posn_valid_r;
  frame_ok_o     <= posn_valid_r;
  sample_count_o <= std_logic_vector(sample_count);


  ----------------------------------------------------------------------------
  -- Output encoding conversion
  ----------------------------------------------------------------------------
  p_pos_encode : process(pos_out, ENCODING, bits_clip)
    variable vbits    : integer;
    variable raw_w    : std_logic_vector(31 downto 0);
    variable bin32    : std_logic_vector(31 downto 0);
    variable sign_bit : std_logic;
    variable tmp      : std_logic_vector(31 downto 0);
    variable i        : integer;
  begin
    vbits := to_integer(bits_clip);  -- 1..32

    raw_w := pos_out;
    if vbits < 32 then
      for i in 0 to 31 loop
        if i >= vbits then
          raw_w(i) := '0';
        end if;
      end loop;
    end if;

    tmp := (others => '0');

    case ENCODING is
      when "00" => -- Unsigned Binary
        tmp := raw_w;

      when "01" => -- Unsigned Gray -> Binary
        bin32 := gray_to_bin(raw_w);
        tmp   := bin32;

      when "10" => -- Signed Binary, sign-extend
        tmp := raw_w;
        sign_bit := raw_w(vbits-1);
        if vbits < 32 then
          for i in 0 to 31 loop
            if i >= vbits then
              tmp(i) := sign_bit;
            end if;
          end loop;
        end if;

      when others => -- "11" Signed Gray -> Binary then sign-extend
        bin32 := gray_to_bin(raw_w);
        tmp   := bin32;
        sign_bit := bin32(vbits-1);
        if vbits < 32 then
          for i in 0 to 31 loop
            if i >= vbits then
              tmp(i) := sign_bit;
            end if;
          end loop;
        end if;
    end case;

    posn_enc <= tmp;
  end process;

   

p_sync : process(clk_i)
  variable rise_now : std_logic;
  variable fall_now : std_logic;
  variable gen_edge : std_logic;
  variable cmd_edge : std_logic;
begin
  if rising_edge(clk_i) then
    if reset_i = '1' then
      -- Clear synchronizers and edge/snapshot outputs
      sck_ff1        <= '0';
      sck_ff2        <= '0';
      dat_ff1        <= '0';
      dat_ff2        <= '0';
      sck_edge_any   <= '0';
      sck_edge_gen   <= '0';
      sck_edge_cmd   <= '0';
      dat_edge_r     <= '0';
      dat_edge_cmd_r <= '0';

    else
      -- existing body of p_sync (unchanged)
      sck_ff1 <= endat_sck_i;
      sck_ff2 <= sck_ff1;

      dat_ff1 <= endat_dat_i;
      dat_ff2 <= dat_ff1;

      sck_edge_any <= (sck_ff1 xor sck_ff2);

      -- rising/falling in clk_i domain (using ff1/ff2)
      rise_now := (sck_ff1 and (not sck_ff2));
      fall_now := ((not sck_ff1) and sck_ff2);

      -- general selected edge (original behavior)
      if SAMPLE_FALL = '1' then
        gen_edge := fall_now;
      else
        gen_edge := rise_now;
      end if;

      -- CMD edge select
      if CMD_BRISING_EDGE /= 0 then
        cmd_edge := rise_now;
      else
        cmd_edge := gen_edge;
      end if;

      sck_edge_gen <= gen_edge;
      sck_edge_cmd <= cmd_edge;

      -- Snapshot DATA on the SAME cycle as GENERAL edge detect
      if gen_edge = '1' then
        if dat_ff1 = dat_ff2 then
          dat_edge_r <= (dat_ff1 xor DATA_INVERT);
        else
          dat_edge_r <= dat_edge_r;
        end if;
      end if;

      -- Snapshot DATA on the SAME cycle as CMD edge detect
      if cmd_edge = '1' then
        if dat_ff1 = dat_ff2 then
          dat_edge_cmd_r <= (dat_ff1 xor DATA_INVERT);
        else
          dat_edge_cmd_r <= dat_edge_cmd_r;
        end if;
      end if;
    end if;
  end if;
end process;


  ----------------------------------------------------------------------------
  -- Next-state / combinational logic
  ----------------------------------------------------------------------------
  p_comb : process(
    st, cmd_idx, pos_idx, crc_rx_idx, seek_cnt,
    sclk_cnt, error_count, frame_error_lat,
    sample_count, posn_valid_r, frame_age_cnt,
    cmd_r, pos_work, pos_out, rx_crc_r,
    link_up_r, err_r,
    idle_cnt, gap_seen,
    sck_edge_gen, sck_edge_cmd, sck_edge_any, dat_edge_r, dat_edge_cmd_r, bits_clip,
    crc_done, crc_calc,
    f1_r, f2_r, timeout_err_r, crc_err_r,
    crc_start_r,
    cmd_lat_r
  )
    variable v_dat       : std_logic;
    variable v_pos_bits  : natural;
    variable age_sat_max : unsigned(31 downto 0);
    variable v_cmd_ok    : boolean;
  begin
    -- Use CMD snapshot only in ST_SYNC/ST_CMD, otherwise use general snapshot
    if (st = ST_SYNC) or (st = ST_CMD) then
      v_dat := dat_edge_cmd_r;
    else
      v_dat := dat_edge_r;
    end if;

    v_pos_bits := to_integer(bits_clip);
    age_sat_max := (others => '1');

    -- Defaults
    st_n <= st;

    cmd_idx_n     <= cmd_idx;
    pos_idx_n     <= pos_idx;
    crc_rx_idx_n  <= crc_rx_idx;
    seek_cnt_n    <= seek_cnt;

    sclk_cnt_n <= sclk_cnt;

    error_count_n     <= error_count;
    frame_error_lat_n <= frame_error_lat;

    sample_count_n    <= sample_count;
    frame_age_cnt_n   <= frame_age_cnt;

    cmd_r_n     <= cmd_r;
    pos_work_n  <= pos_work;
    pos_out_n   <= pos_out;
    rx_crc_r_n  <= rx_crc_r;

    link_up_r_n <= link_up_r;
    err_r_n     <= err_r;

    idle_cnt_n  <= idle_cnt;
    gap_seen_n  <= gap_seen;

    crc_start_r_n   <= '0'; -- pulse
    posn_valid_r_n  <= '0';

    -- Health sticky bits
    f1_r_n          <= f1_r;
    f2_r_n          <= f2_r;
    timeout_err_r_n <= timeout_err_r;
    crc_err_r_n     <= crc_err_r;

    -- CMD latch defaults
    cmd_lat_r_n     <= cmd_lat_r;
    cmd_valid_r_n   <= '0';

    --------------------------------------------------------------------------
    -- frame_age counter (clk_i domain)
    --------------------------------------------------------------------------
    if frame_age_cnt < age_sat_max then
      frame_age_cnt_n <= frame_age_cnt + 1;
    end if;

    --------------------------------------------------------------------------
    -- stale detection (optional)
    --------------------------------------------------------------------------
    if FRAME_STALE_CLKS /= 0 then
      if frame_age_cnt_n >= to_unsigned(FRAME_STALE_CLKS, frame_age_cnt_n'length) then
        link_up_r_n <= '0';
      end if;
    end if;

    --------------------------------------------------------------------------
    -- idle counter update (any SCK transition)
    --------------------------------------------------------------------------
    if sck_edge_any = '1' then
      idle_cnt_n <= (others => '0');
    else
      if idle_cnt < to_unsigned(65535, idle_cnt'length) then
        idle_cnt_n <= idle_cnt + 1;
      end if;
    end if;

    if idle_cnt_n >= to_unsigned(IDLE_GAP_CLKS, idle_cnt_n'length) then
      gap_seen_n <= '1';
    end if;

    --------------------------------------------------------------------------
    -- CRC done handling (clk_i domain)
    --------------------------------------------------------------------------
    if st = ST_CRC_CALC then
      if crc_done = '1' then
        if CRC_BYPASS = 1 then
          link_up_r_n   <= '1';
          err_r_n       <= '0';
          pos_out_n     <= pos_work;

          sample_count_n  <= sample_count + 1;
          frame_age_cnt_n <= (others => '0');
        else
          if rx_crc_r = crc_calc then
            link_up_r_n   <= '1';
            err_r_n       <= '0';

            sample_count_n  <= sample_count + 1;
            frame_age_cnt_n <= (others => '0');
          else
            err_r_n     <= '1';
            crc_err_r_n <= '1';
            if frame_error_lat = '0' then
              error_count_n     <= error_count + 1;
              frame_error_lat_n <= '1';
            end if;
          end if;
        end if;

        st_n <= ST_SYNC;
      end if;
    end if;

    --------------------------------------------------------------------------
    -- State machine advances:
    --   - ST_SYNC / ST_CMD use CMD edge (optional rising-only)
    --   - other states use general selected edge
    --------------------------------------------------------------------------
    if ((st = ST_SYNC) or (st = ST_CMD)) then
      if sck_edge_cmd = '1' then
        case st is

          when ST_SYNC =>
            if gap_seen = '1' then
              gap_seen_n <= '0';
              idle_cnt_n <= (others => '0');

              frame_error_lat_n <= '0';
              err_r_n           <= '0';

              f1_r_n          <= '0';
              f2_r_n          <= '0';
              timeout_err_r_n <= '0';
              crc_err_r_n     <= '0';

              cmd_r_n      <= (others => '0');
              pos_work_n   <= (others => '0');
              rx_crc_r_n   <= (others => '0');

              seek_cnt_n   <= (others => '0');
              pos_idx_n    <= (others => '0');
              crc_rx_idx_n <= (others => '0');

              sclk_cnt_n <= to_unsigned(1, sclk_cnt_n'length);

              cmd_r_n(C_MODE_BITS-1) <= v_dat;
              cmd_idx_n <= to_unsigned(1, cmd_idx_n'length);

              st_n <= ST_CMD;
            end if;

          when ST_CMD =>
            sclk_cnt_n <= sclk_cnt + 1;

            cmd_r_n(C_MODE_BITS-1 - to_integer(cmd_idx)) <= v_dat;

            if to_integer(cmd_idx) = C_MODE_BITS-1 then
              cmd_idx_n  <= (others => '0');
              seek_cnt_n <= (others => '0');

              if CMD_CHECK_EN = 0 then
                v_cmd_ok := true;
              else
                v_cmd_ok := (cmd_r_n = C_CMD_POS);
              end if;

              if v_cmd_ok then
                st_n <= ST_SEEK_START;
              else
                err_r_n <= '1';
                if frame_error_lat = '0' then
                  error_count_n     <= error_count + 1;
                  frame_error_lat_n <= '1';
                end if;
                st_n <= ST_SYNC;
              end if;
            else
              cmd_idx_n <= cmd_idx + 1;
            end if;

          when others =>
            st_n <= ST_SYNC;

        end case;
      end if;

    else
      if sck_edge_gen = '1' then
        case st is

          when ST_SEEK_START =>
            sclk_cnt_n <= sclk_cnt + 1;

            if to_integer(seek_cnt) = integer(C_SEEK_START_TIMEOUT) then
              err_r_n          <= '1';
              timeout_err_r_n  <= '1';
              if frame_error_lat = '0' then
                error_count_n     <= error_count + 1;
                frame_error_lat_n <= '1';
              end if;
              st_n <= ST_SYNC;
            else
              seek_cnt_n <= seek_cnt + 1;

              if v_dat = '1' then
                -- START found (not included in CRC)
                pos_work_n   <= (others => '0');
                rx_crc_r_n   <= (others => '0');
                pos_idx_n    <= (others => '0');
                crc_rx_idx_n <= (others => '0');

                st_n <= ST_F1;
              end if;
            end if;

          when ST_F1 =>
            sclk_cnt_n <= sclk_cnt + 1;
            f1_r_n <= v_dat;

            if G_ENDAT2_2 = 1 then
              st_n <= ST_F2;
            else
              f2_r_n <= '0';
              st_n   <= ST_POS;
            end if;

          when ST_F2 =>
            sclk_cnt_n <= sclk_cnt + 1;
            f2_r_n <= v_dat;
            st_n   <= ST_POS;

          when ST_POS =>
            sclk_cnt_n <= sclk_cnt + 1;

            if to_integer(pos_idx) <= 31 then
              pos_work_n(to_integer(pos_idx)) <= v_dat;
            end if;

            if to_integer(pos_idx) = integer(v_pos_bits)-1 then
              pos_idx_n    <= (others => '0');
              crc_rx_idx_n <= (others => '0');
              st_n         <= ST_CRC_RX;
            else
              pos_idx_n <= pos_idx + 1;
            end if;

          when ST_CRC_RX =>
            sclk_cnt_n <= sclk_cnt + 1;

            -- Capture CRC field MSB-first
            rx_crc_r_n(4 - to_integer(crc_rx_idx)) <= v_dat;

            if to_integer(crc_rx_idx) = C_CRC_BITS-1 then
              crc_rx_idx_n <= (others => '0');

              -- Kick off parallel CRC calculation (clk_i domain)
              crc_start_r_n <= '1';

              -- Commit position (this generates posn_valid pulse)
              posn_valid_r_n <= '1';
              pos_out_n      <= pos_work;

              st_n           <= ST_CRC_CALC;
            else
              crc_rx_idx_n <= crc_rx_idx + 1;
            end if;

          when ST_CRC_CALC =>
            null;

          when others =>
            st_n <= ST_SYNC;

        end case;
      end if;
    end if;

    --------------------------------------------------------------------------
    -- NEW: latch CMD when we assert posn_valid pulse (same frame commit point)
    --------------------------------------------------------------------------
    if posn_valid_r_n = '1' then
      cmd_lat_r_n   <= cmd_r;   -- cmd_r is stable by this point
      cmd_valid_r_n <= '1';
    end if;

  end process;

  ----------------------------------------------------------------------------
  -- Registers
  ----------------------------------------------------------------------------
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if reset_i = '1' then
        st <= ST_SYNC;

        cmd_idx    <= (others => '0');
        pos_idx    <= (others => '0');
        crc_rx_idx <= (others => '0');
        seek_cnt   <= (others => '0');

        sclk_cnt <= (others => '0');

        error_count     <= (others => '0');
        frame_error_lat <= '0';

        sample_count  <= (others => '0');
        posn_valid_r  <= '0';
        frame_age_cnt <= (others => '0');

        cmd_r     <= (others => '0');
        pos_work  <= (others => '0');
        pos_out   <= (others => '0');
        rx_crc_r  <= (others => '0');

        link_up_r <= '0';
        err_r     <= '0';

        idle_cnt <= (others => '0');
        gap_seen <= '0';

        crc_start_r <= '0';

        f1_r          <= '0';
        f2_r          <= '0';
        timeout_err_r <= '0';
        crc_err_r     <= '0';

        cmd_lat_r     <= (others => '0');
        cmd_valid_r   <= '0';

      else
        st <= st_n;

        cmd_idx    <= cmd_idx_n;
        pos_idx    <= pos_idx_n;
        crc_rx_idx <= crc_rx_idx_n;
        seek_cnt   <= seek_cnt_n;

        sclk_cnt <= sclk_cnt_n;

        error_count     <= error_count_n;
        frame_error_lat <= frame_error_lat_n;

        sample_count  <= sample_count_n;
        posn_valid_r  <= posn_valid_r_n;
        frame_age_cnt <= frame_age_cnt_n;

        cmd_r     <= cmd_r_n;
        pos_work  <= pos_work_n;
        pos_out   <= pos_out_n;
        rx_crc_r  <= rx_crc_r_n;

        link_up_r <= link_up_r_n;
        err_r     <= err_r_n;

        idle_cnt <= idle_cnt_n;
        gap_seen <= gap_seen_n;

        crc_start_r <= crc_start_r_n;

        f1_r          <= f1_r_n;
        f2_r          <= f2_r_n;
        timeout_err_r <= timeout_err_r_n;
        crc_err_r     <= crc_err_r_n;

        cmd_lat_r     <= cmd_lat_r_n;
        cmd_valid_r   <= cmd_valid_r_n;
      end if;
    end if;
  end process;


  ----------------------------------------------------------------------------
  -- External CRC module instance
  ----------------------------------------------------------------------------
  u_endat_crc5 : entity work.endat_crc5
  generic map (
    G_ENDAT2_2 => G_ENDAT2_2
  )
  port map (
      clk         => clk_i,
      rst_n       => not reset_i,
      start_i     => crc_start_r,
      num_bits_i  => BITS,           -- POSITION bit-length (e.g., 25)
      data_i      => pos_work,        -- LSB-first position bits (no header)
      err_f1_i    => f1_r,            -- F1
      err_f2_i    => f2_r,            -- F2
      busy_o      => crc_busy,
      done_o      => crc_done,
      crc_o       => crc_calc
    );
    

  -- Health bit map
  -- bit0 OK
  -- bit1 Linkup error (=not CONN)
  -- bit2 Timeout error
  -- bit3 CRC error
  -- bit4 Error bit active (F1 or F2)
  -- bit5 ENDAT not implemented   : 0
  -- bit6 Protocol readback error : 0
  health_o <= (31 downto 7 => '0') &
              '0' &  -- bit6
              '0' &  -- bit5
              (f1_r or f2_r) &  -- bit4
              crc_err_r &       -- bit3
              timeout_err_r &   -- bit2
              (not link_up_r) & -- bit1
              (link_up_r and (timeout_err_r or crc_err_r or (f1_r or f2_r))); -- bit0
                  
end architecture;

