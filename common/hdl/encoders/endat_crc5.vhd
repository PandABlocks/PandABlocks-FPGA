


--Input stream (LSB-first): [F1] + position[bit0..bit24].
--LFSR seed: 11111.
--Per-bit update: ex = s4 ⊕ bit_in, then
--s4' = s3, s3' = s2 ⊕ ex, s2' = s1, s1' = s0 ⊕ ex, s0' = ex.
--Final step: bitwise complement of the state, read out MSB→LSB to form 5-bit CRC.
--Polynomial (in this convention): G(x)=x5+x2+1G(x) = x^5 + x^2 + 1G(x)=x5+x2+1.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- EnDat CRC-5 over a bit vector, LSB-first
-- LFSR init = 11111, update per bit:
--   ex = ff(4) XOR bit_in
--   ff(4) <- ff(3)
--   ff(3) <- ff(2) XOR ex
--   ff(2) <- ff(1)
--   ff(1) <- ff(0) XOR ex
--   ff(0) <- ex
-- After all bits, CRC output = NOT ff(4)..NOT ff(0) (MSB..LSB)
--
-- G_ENDAT2_2 determines the header length:
--   0: Include F1 only  (num_bits = position_bits + 1)
--   1: Include F1 + F2  (num_bits = position_bits + 2)
--
-- On start_i, data_reg is constructed internally:
--   G_ENDAT2_2=0: data_reg <= data_i(30 downto 0) & f1_r           -- LSB = F1
--   G_ENDAT2_2=1: data_reg <= data_i(29 downto 0) & err_f2_i & err_f1_i  -- LSB = F1, next = F2
--
-- data_i carries POSITION bits (LSB-first) only.

entity endat_crc5 is
  generic (
    G_ENDAT2_2 : natural := 0  -- 0: include F1 only; 1: include F1 + F2 (EnDat 2.2 framing)
  );
  port (
    clk         : in  std_logic;
    rst_n       : in  std_logic;

    start_i     : in  std_logic;  -- single-cycle pulse to start

    -- Provide POSITION bit-length only (e.g., 25).
    -- The module will add +1 (F1) or +2 (F1+F2) internally, based on G_ENDAT2_2.
    num_bits_i  : in  std_logic_vector(7 downto 0);

    -- POSITION bits LSB-first in data_i.
    -- F1/F2 are provided on separate ports err_f1_i / err_f2_i and will be prepended internally.
    data_i      : in  std_logic_vector(31 downto 0);

    -- Header error bits (F1/F2), LSB-first consumption order:
    --   For G_ENDAT2_2=0: only F1 is used.
    --   For G_ENDAT2_2=1: F1 is first, then F2.
    err_f1_i    : in  std_logic;
    err_f2_i    : in  std_logic;

    busy_o      : out std_logic;  -- asserted while processing bits
    done_o      : out std_logic;  -- single-cycle pulse when CRC is ready
    crc_o       : out std_logic_vector(4 downto 0)  -- MSB..LSB after bitwise complement
  );
end entity;

architecture rtl of endat_crc5 is
  -- LFSR state (5 bits), initialized to all-ones (11111).
  signal ff_r          : std_logic_vector(4 downto 0) := (others => '1');

  -- Latched input data and computed bit-count.
  signal data_reg      : std_logic_vector(31 downto 0) := (others => '0');
  signal num_bits_reg  : unsigned(7 downto 0) := (others => '0');

  -- Current bit index (LSB-first), control and output.
  signal idx_r         : unsigned(7 downto 0) := (others => '0');
  signal busy_r        : std_logic := '0';
  signal done_r        : std_logic := '0';
  signal crc_r         : std_logic_vector(4 downto 0) := (others => '0');

  -- Internal aliases for clarity
  signal f1_r          : std_logic;
  signal f2_r          : std_logic;
begin
  -- Alias external inputs
  f1_r <= err_f1_i;
  f2_r <= err_f2_i;

  busy_o <= busy_r;
  done_o <= done_r;
  crc_o  <= crc_r;

  process(clk, rst_n)
    variable bit_in_v : std_logic;                 -- current input bit
    variable ex_v     : std_logic;                 -- ex = ff(4) XOR bit_in
    variable f_next   : std_logic_vector(4 downto 0); -- next LFSR state
    variable nb_u     : unsigned(7 downto 0);      -- local unsigned copy of num_bits_i
  begin
    if rst_n = '0' then
      -- Asynchronous active-low reset
      ff_r         <= (others => '1');   -- LFSR init = 11111
      data_reg     <= (others => '0');
      num_bits_reg <= (others => '0');
      idx_r        <= (others => '0');
      busy_r       <= '0';
      done_r       <= '0';
      crc_r        <= (others => '0');

    elsif rising_edge(clk) then
      -- default: clear done pulse
      done_r <= '0';

      if busy_r = '0' then
        -- Idle: wait for start pulse
        if start_i = '1' then
          -- Build the working bit vector inside the module (LSB-first):
          -- HEADER (F1[,F2]) + POSITION bits from data_i
          if G_ENDAT2_2 = 0 then
            -- Use 31 bits from data_i (position) and append F1 as LSB: total 32 bits
            -- Result mapping: data_reg(0) = F1, data_reg(31 downto 1) = data_i(30 downto 0)
            data_reg <= data_i(30 downto 0) & f1_r;
          else
            -- Use 30 bits from data_i (position), append F2 then F1 as LSBs: total 32 bits
            -- Result mapping: data_reg(0)=F1, data_reg(1)=F2, data_reg(31 downto 2)=data_i(29 downto 0)
            data_reg <= data_i(29 downto 0) & f2_r & f1_r;
          end if;

          -- num_bits_i carries POSITION bit-length only.
          -- Add header bits depending on G_ENDAT2_2:
          nb_u := unsigned(num_bits_i);
          if G_ENDAT2_2 = 0 then
            num_bits_reg <= nb_u + 1;  -- include F1
          else
            num_bits_reg <= nb_u + 2;  -- include F1 + F2
          end if;

          -- Initialize processing
          idx_r  <= (others => '0');
          ff_r   <= (others => '1');   -- LFSR init = 11111
          busy_r <= '1';
        end if;

      else
        -- Busy: process one bit per cycle (LSB-first)
        if to_integer(idx_r) < to_integer(num_bits_reg) then
          -- Consume current bit from data_reg (LSB-first)
          bit_in_v := data_reg(to_integer(idx_r));

          -- LFSR update per bit:
          -- ex = ff(4) XOR bit_in
          ex_v     := ff_r(4) xor bit_in_v;

          -- next state mapping (matches Python reference):
          f_next(4) := ff_r(3);
          f_next(3) := ff_r(2) xor ex_v;
          f_next(2) := ff_r(1);
          f_next(1) := ff_r(0) xor ex_v;
          f_next(0) := ex_v;

          -- Apply next state
          ff_r <= f_next;

          -- Last bit processed?
          if idx_r = (num_bits_reg - 1) then
            busy_r <= '0';
            done_r <= '1';
            -- Output CRC: bitwise complement (~) of LFSR, MSB..LSB
            crc_r  <= (not f_next(4)) & (not f_next(3)) & (not f_next(2)) & (not f_next(1)) & (not f_next(0));
          else
            -- Advance to next bit
            idx_r <= idx_r + 1;
          end if;

        else
          -- Safety: if num_bits_reg = 0, finish with complement of initial state
          busy_r <= '0';
          done_r <= '1';
          crc_r  <= (not ff_r(4)) & (not ff_r(3)) & (not ff_r(2)) & (not ff_r(1)) & (not ff_r(0));
        end if;
      end if;
    end if;
  end process;
end architecture;




--def endat_crc5_with_f1(position_value: int, f1: int, num_pos_bits: int = 25) -> int:
--    """
--    Compute EnDat CRC-5 over a 26-bit LSB-first stream constructed as:
--      [F1] + [position bit0, bit1, ..., bit24]

--    Conventions:
--      - LFSR initial state: 11111 (all ones)
--      - Input order: LSB-first (F1 first, then position bit0 → bit24)
--      - Final step: bitwise complement of the LFSR state before output
--      - Output: read MSB→LSB of the complemented state to form a 5-bit integer (0..31)

--    The LFSR update corresponds to the CRC-5 polynomial:
--      G(x) = x^5 + x^2 + 1
--    under LSB-first processing with an all-ones seed and final complement.

--    Args:
--        position_value: Position value as an integer; only the lowest `num_pos_bits` are used.
--        f1: Fault1 bit (0 or 1); this is processed first (LSB).
--        num_pos_bits: Number of position bits to process (default: 25).

--    Returns:
--        5-bit CRC as an integer in the range 0..31.
--    """
--    # Use only the lowest `num_pos_bits` of the position and ensure f1 is a single bit
--    position_value &= (1 << num_pos_bits) - 1
--    f1 &= 1

--    # ---- LFSR initial state: all ones (11111) ----
--    # ff[0] is LSB of the register, ff[4] is MSB
--    ff = [1, 1, 1, 1, 1]

--    def lfsr_update(bit_in: int):
--        """
--        Process one input bit using the CRC-5 LFSR update rule.

--        State transition (with ex = s4 XOR bit_in):
--            s4' = s3
--            s3' = s2 XOR ex
--            s2' = s1
--            s1' = s0 XOR ex
--            s0' = ex
--        """
--        ex = ff[4] ^ bit_in
--        ff[4] = ff[3]
--        ff[3] = ff[2] ^ ex
--        ff[2] = ff[1]
--        ff[1] = ff[0] ^ ex
--        ff[0] = ex

--    # 1) Process F1 bit first (LSB in the stream)
--    lfsr_update(f1)

--    # 2) Process the position bits in LSB-first order: bit0 → bit(num_pos_bits-1)
--    for i in range(num_pos_bits):
--        bit = (position_value >> i) & 1
--        lfsr_update(bit)

--    # ---- Final complement (~) and assemble 5-bit CRC MSB→LSB ----
--    crc = 0
--    for i in range(4, -1, -1):
--        # Complement each bit: output 0 if register bit is 1, output 1 if register bit is 0
--        crc = (crc << 1) | (0 if ff[i] else 1)

--    return crc & 0x1F  # Ensure result is 5 bits
    