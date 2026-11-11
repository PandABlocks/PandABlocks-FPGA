-- Hamming (16,11) SECDED check and correction for the Zygo ZMI serial bus
--
-- ZMI 4100 serial frame, 32 bit position words (ZMI 4100 Series
-- Measurement Board manual, Table 3-12):
--
--   frame bit  0     : start
--   frame bits 1..16 : block 1  P1 P2 Pos<0>  P4 Pos<1..3>   P8 Pos<4..10>        Pt
--   frame bits 17..32: block 2  P1 P2 Pos<11> P4 Pos<12..14> P8 Pos<15..21>       Pt
--   frame bits 33..48: block 3  P1 P2 Pos<22> P4 Pos<23..25> P8 Pos<26..31> Zmi_err Pt
--   frame bit  49    : stop
--
-- data_i(n) holds frame bit n+1, i.e. block k occupies data_i(16*k+15 downto 16*k)
-- and Hamming position p (1..16) of a block is data_i(16*k+p-1).
-- Positions 1, 2, 4, 8 are the Hamming check bits, positions 3,5-7,9-15 the
-- data bits and position 16 (Pt) is the overall parity over positions 1..15.
--
-- Per block:
--   syndrome = 0, parity ok    : no error
--   syndrome = 0, parity bad   : Pt bit itself wrong, data ok      (corrected)
--   syndrome /= 0, parity bad  : single bit error at 'syndrome'    (corrected)
--   syndrome /= 0, parity ok   : double bit error                  (uncorrectable)
--
-- Latency: 2 clock cycles from valid_i to valid_o.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity zmi_hamming is
generic (
    -- '0' = even parity (standard Hamming), '1' = odd parity
    ODD_PARITY      : std_logic := '0'
);
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Received frame bits 1..48 (without start and stop bit)
    data_i          : in  std_logic_vector(47 downto 0);
    valid_i         : in  std_logic;
    -- Checked and corrected frame content
    posn_o          : out std_logic_vector(31 downto 0);
    zmi_err_o       : out std_logic;
    valid_o         : out std_logic;
    -- Frame check result (valid together with valid_o)
    corrected_o     : out std_logic;    -- single bit error(s) corrected
    uncorrectable_o : out std_logic;    -- double bit error detected
    block_err_o     : out std_logic_vector(2 downto 0)  -- uncorrectable per block
);
end zmi_hamming;

architecture rtl of zmi_hamming is

type syndrome_array_t is array (0 to 2) of unsigned(3 downto 0);

signal data_s1          : std_logic_vector(47 downto 0);
signal syndrome_s1      : syndrome_array_t;
signal parity_err_s1    : std_logic_vector(2 downto 0);
signal valid_s1         : std_logic;

-- Hamming syndrome over positions 1..15 of a 16 bit block
function syndrome(blk : std_logic_vector(15 downto 0)) return unsigned is
    variable s : unsigned(3 downto 0) := (others => '0');
begin
    for p in 1 to 15 loop
        if blk(p-1) = '1' then
            s := s xor to_unsigned(p, 4);
        end if;
    end loop;
    -- Odd parity: each check bit is inverted relative to even parity
    if ODD_PARITY = '1' then
        s := not s;
    end if;
    return s;
end function;

-- Overall parity check over all 16 bits, '1' = parity error
function parity_err(blk : std_logic_vector(15 downto 0)) return std_logic is
    variable x : std_logic := ODD_PARITY;
begin
    for p in 0 to 15 loop
        x := x xor blk(p);
    end loop;
    return x;
end function;

begin

--------------------------------------------------------------------------
-- Stage 1: syndrome and overall parity per block
--------------------------------------------------------------------------
stage1 : process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            valid_s1 <= '0';
        else
            valid_s1 <= valid_i;
        end if;

        if valid_i = '1' then
            data_s1 <= data_i;
            for k in 0 to 2 loop
                syndrome_s1(k) <= syndrome(data_i(16*k+15 downto 16*k));
                parity_err_s1(k) <= parity_err(data_i(16*k+15 downto 16*k));
            end loop;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Stage 2: single bit correction, error classification, data extraction
--------------------------------------------------------------------------
stage2 : process(clk_i)
    variable data_cor   : std_logic_vector(47 downto 0);
    variable corrected  : std_logic;
    variable block_err  : std_logic_vector(2 downto 0);
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            valid_o <= '0';
        else
            valid_o <= valid_s1;
        end if;

        if valid_s1 = '1' then
            data_cor  := data_s1;
            corrected := '0';
            block_err := (others => '0');

            for k in 0 to 2 loop
                if parity_err_s1(k) = '1' then
                    -- Single bit error: flip the addressed bit. Syndrome 0
                    -- means Pt itself is wrong, which carries no data.
                    corrected := '1';
                    for p in 1 to 15 loop
                        if syndrome_s1(k) = to_unsigned(p, 4) then
                            data_cor(16*k+p-1) := not data_s1(16*k+p-1);
                        end if;
                    end loop;
                elsif syndrome_s1(k) /= 0 then
                    -- Double bit error: not correctable
                    block_err(k) := '1';
                end if;
            end loop;

            -- Extract data bits (Hamming positions 3,5,6,7,9..15)
            posn_o(0)            <= data_cor(2);
            posn_o(3 downto 1)   <= data_cor(6 downto 4);
            posn_o(10 downto 4)  <= data_cor(14 downto 8);
            posn_o(11)           <= data_cor(18);
            posn_o(14 downto 12) <= data_cor(22 downto 20);
            posn_o(21 downto 15) <= data_cor(30 downto 24);
            posn_o(22)           <= data_cor(34);
            posn_o(25 downto 23) <= data_cor(38 downto 36);
            posn_o(31 downto 26) <= data_cor(45 downto 40);
            zmi_err_o            <= data_cor(46);

            corrected_o     <= corrected;
            uncorrectable_o <= block_err(0) or block_err(1) or block_err(2);
            block_err_o     <= block_err;
        end if;
    end if;
end process;

end rtl;
