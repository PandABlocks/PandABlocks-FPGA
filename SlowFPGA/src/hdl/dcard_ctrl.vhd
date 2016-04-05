--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Daughter Card control logic for on-board buffers based on the
--                PROTOCOL and CARD MODE.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity dcard_ctrl is
port (
    -- 50MHz system clock
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Encoder Daughter Card Control Interface
    dcard_ctrl1_io      : inout std_logic_vector(15 downto 0);
    dcard_ctrl2_io      : inout std_logic_vector(15 downto 0);
    dcard_ctrl3_io      : inout std_logic_vector(15 downto 0);
    dcard_ctrl4_io      : inout std_logic_vector(15 downto 0);
    -- Front Panel Shift Register Interface
    INENC_PROTOCOL      : in  std3_array(3 downto 0);
    OUTENC_PROTOCOL     : in  std3_array(3 downto 0);
    DCARD_MODE          : out std4_array(3 downto 0)
);
end dcard_ctrl;

architecture rtl of dcard_ctrl is

function INENC_CONV (PROTOCOL : std_logic_vector) return std_logic_vector is
begin
    case (PROTOCOL(2 downto 0)) is
        when "000"  => -- INC
            return X"03";
        when "001"  => -- SSI
            return X"0C";
        when "010"  => -- EnDat
            return X"14";
        when "011"  => -- BiSS
            return X"1C";
        when others =>
            return X"00";
    end case;
end INENC_CONV;

function OUTENC_CONV (PROTOCOL : std_logic_vector) return std_logic_vector is
begin
    case (PROTOCOL(2 downto 0)) is
        when "000"  => -- INC
            return X"07";
        when "001"  => -- SSI
            return X"28";
        when "010"  => -- EnDat
            return X"10";
        when "011"  => -- BiSS
            return X"18";
        when "100"  => -- Pass
            return X"07";
        when others =>
            return X"00";
    end case;
end OUTENC_CONV;

function CONV_PADS(INENC, OUTENC : std_logic_vector) return std_logic_vector is
    variable enc_ctrl_pad : std_logic_vector(11 downto 0);
begin

    enc_ctrl_pad(1 downto 0) := INENC(1 downto 0);
    enc_ctrl_pad(3 downto 2) := OUTENC(1 downto 0);
    enc_ctrl_pad(4) := INENC(2);
    enc_ctrl_pad(5) := OUTENC(2);
    enc_ctrl_pad(7 downto 6) := INENC(4 downto 3);
    enc_ctrl_pad(9 downto 8) := OUTENC(4 downto 3);
    enc_ctrl_pad(10) := INENC(5);
    enc_ctrl_pad(11) := OUTENC(5);

    return enc_ctrl_pad;
end CONV_PADS;

signal inenc_ctrl1      : std_logic_vector(7 downto 0);
signal inenc_ctrl2      : std_logic_vector(7 downto 0);
signal inenc_ctrl3      : std_logic_vector(7 downto 0);
signal inenc_ctrl4      : std_logic_vector(7 downto 0);

signal outenc_ctrl1     : std_logic_vector(7 downto 0);
signal outenc_ctrl2     : std_logic_vector(7 downto 0);
signal outenc_ctrl3     : std_logic_vector(7 downto 0);
signal outenc_ctrl4     : std_logic_vector(7 downto 0);

begin

-- Assign CTRL values for Input Encoder ICs on the Daughter Card
inenc_ctrl1 <= INENC_CONV(INENC_PROTOCOL(0));
inenc_ctrl2 <= INENC_CONV(INENC_PROTOCOL(1));
inenc_ctrl3 <= INENC_CONV(INENC_PROTOCOL(2));
inenc_ctrl4 <= INENC_CONV(INENC_PROTOCOL(3));

-- Assign CTRL values for Output Encoder ICs on the Daughter Card
outenc_ctrl1 <= OUTENC_CONV(OUTENC_PROTOCOL(0));
outenc_ctrl2 <= OUTENC_CONV(OUTENC_PROTOCOL(1));
outenc_ctrl3 <= OUTENC_CONV(OUTENC_PROTOCOL(2));
outenc_ctrl4 <= OUTENC_CONV(OUTENC_PROTOCOL(3));

-- Interleave Input and Output Controls to the Daughter Card Pins.
dcard_ctrl1_io(11 downto 0) <= CONV_PADS(inenc_ctrl1, outenc_ctrl1);
dcard_ctrl2_io(11 downto 0) <= CONV_PADS(inenc_ctrl2, outenc_ctrl2);
dcard_ctrl3_io(11 downto 0) <= CONV_PADS(inenc_ctrl3, outenc_ctrl3);
dcard_ctrl4_io(11 downto 0) <= CONV_PADS(inenc_ctrl4, outenc_ctrl4);

-- DCARD configuration from on-board 0-Ohm settings.
DCARD_MODE(0) <= dcard_ctrl1_io(15 downto 12);
DCARD_MODE(1) <= dcard_ctrl2_io(15 downto 12);
DCARD_MODE(2) <= dcard_ctrl3_io(15 downto 12);
DCARD_MODE(3) <= dcard_ctrl4_io(15 downto 12);

dcard_ctrl1_io(15 downto 12) <= "ZZZZ";
dcard_ctrl2_io(15 downto 12) <= "ZZZZ";
dcard_ctrl3_io(15 downto 12) <= "ZZZZ";
dcard_ctrl4_io(15 downto 12) <= "ZZZZ";

end rtl;
