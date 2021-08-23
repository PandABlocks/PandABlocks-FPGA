--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Daughter Card control logic for on-board buffers based on :
--                PROTOCOL,
--                DCARD MODE, and
--                OUTENC_CONN connection from user.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.slow_defines.all;

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
    OUTENC_CONN         : in  std_logic_vector(3 downto 0);
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
        when "010"  => -- BiSS-C
            return X"0C";
        when "011"  => -- EnDat
            return X"14";
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
        when "010"  => -- BiSS-C
            return X"28";
        when "011"  => -- EnDat
            return X"10";
        when "100"  => -- Pass
            return X"07";
        when "101" => -- Data passthrough (same as SSI)
            return X"28";
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

signal DCARD_MODE_i     : std4_array(3 downto 0)
                            := (others => (others => '0'));
signal inenc_ctrl       : std8_array(3 downto 0);
signal outenc_ctrl      : std8_array(3 downto 0);

begin

-- DCARD configuration from on-board 0-Ohm settings.
-- These pins have weak pull-ups on the chip to detect
-- un-installed daughter cards
DCARD_MODE_i(0) <= dcard_ctrl1_io(15 downto 12);
DCARD_MODE_i(1) <= dcard_ctrl2_io(15 downto 12);
DCARD_MODE_i(2) <= dcard_ctrl3_io(15 downto 12);
DCARD_MODE_i(3) <= dcard_ctrl4_io(15 downto 12);

-- Assign CTRL values for Input Encoder ICs on the Daughter Card
INENC_CTRL_GEN : FOR I IN 0 TO 3 GENERATE
    inenc_ctrl(I) <= INENC_CONV(INENC_PROTOCOL(I));
END GENERATE;

-- Output Encoder Buffer Control depends on Daughter Card Mode, Protocol, and
-- OUTENC_CONN setting.
--
process(INENC_PROTOCOL, OUTENC_PROTOCOL, DCARD_MODE_i, OUTENC_CONN)
begin
    FOR I IN 0 TO 3 LOOP
        -- Disable all OUTENC buffers. ???
        if (OUTENC_CONN(I) = '0') then
            outenc_ctrl(I) <= OUTENC_CONV(OUTENC_PROTOCOL(I));
        -- Daugther Card in LOOPBACK mode.
        elsif (DCARD_MODE_i(I)(3 downto 1) = DCARD_MONITOR) then
            outenc_ctrl(I) <= OUTENC_CONV(INENC_PROTOCOL(I));
        -- Daughter Card in NORMAL mode.
        else
            outenc_ctrl(I) <= OUTENC_CONV(OUTENC_PROTOCOL(I));
        end if;
    END LOOP;
end process;

-- Interleave Input and Output Controls to the Daughter Card Pins.
dcard_ctrl1_io(11 downto 0) <= CONV_PADS(inenc_ctrl(0), outenc_ctrl(0));
dcard_ctrl2_io(11 downto 0) <= CONV_PADS(inenc_ctrl(1), outenc_ctrl(1));
dcard_ctrl3_io(11 downto 0) <= CONV_PADS(inenc_ctrl(2), outenc_ctrl(2));
dcard_ctrl4_io(11 downto 0) <= CONV_PADS(inenc_ctrl(3), outenc_ctrl(3));

DCARD_MODE <= DCARD_MODE_i;

end rtl;
