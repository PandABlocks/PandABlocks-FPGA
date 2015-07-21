LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

library unisim;
use unisim.vcomponents.all;

library work;
use work.test_interface.all;

entity daughter_card_model is
port (
    -- Front Panel via DB15
    A_IN_P      : in  std_logic;
    B_IN_P      : in  std_logic;
    Z_IN_P      : in  std_logic;
    CLK_OUT_P   : out std_logic;
    DATA_IN_P   : in  std_logic;

    A_OUT_P     : out std_logic;
    B_OUT_P     : out std_logic;
    Z_OUT_P     : out std_logic;
    CLK_IN_P    : in  std_logic;
    DATA_OUT_P  : out std_logic;

    -- FMC Interface
    A_IN        : inout  std_logic;
    B_IN        : inout  std_logic;
    Z_IN        : inout  std_logic;

    A_OUT       : inout std_logic;
    B_OUT       : inout std_logic;
    Z_OUT       : inout std_logic;

    CTRL_IN     : in  std_logic_vector(11 downto 0);
    CTRL_OUT    : out std_logic_vector(3  downto 0)
);
end daughter_card_model;

architecture behavior of daughter_card_model is

signal mux1         : std_logic_vector(1 downto 0);
signal mux2         : std_logic_vector(1 downto 0);
signal CTRL_IN_N    : std_logic_vector(11 downto 0);

begin

-- Not used
CTRL_OUT <= "0000";

CTRL_IN_N <= not CTRL_IN;

-- These are the 74VHD153 Multiplexer chips on the board.
process(CTRL_IN)
begin
    case (ctrl_in(7 downto 6)) is
        when "00" => mux1 <= "10";
        when "01" => mux1 <= "00";
        when "10" => mux1 <= Z_IN & Z_IN;
        when "11" => mux1 <= "11";
        when others => mux1 <= "10";
    end case;

    case (ctrl_in(9 downto 8)) is
        when "00" => mux2 <= "10";
        when "01" => mux2 <= "11";
        when "10" => mux2 <= Z_OUT & Z_OUT;
        when "11" => mux2 <= "00";
        when others => mux2 <= "10";
    end case;

end process;

-- Input/Master Buffers
AIN: IOBUF port map (
I=>A_IN_P, O=>open, T=>CTRL_IN_N(0), IO=>A_IN);

BIN: IOBUF port map (
I=>B_IN_P, O=>open, T=>CTRL_IN_N(0), IO=>B_IN);

ZIN: IOBUF port map (
I=>Z_IN_P, O=>open, T=>CTRL_IN_N(1), IO=>Z_IN);

--CLK_OUT: IOBUF port map (
--I=>'0', O=>CLK_OUT_P, T=>'1', IO=>B_IN);
--
--DATA_IN: IOBUF port map (
--I=>DATA_IN_P, O=>open, T=>mux1(1), IO=>A_IN);

-- Output/Slave Buffers
AOUT: IOBUF port map (
I=>'0', O=>A_OUT_P, T=>CTRL_IN(2), IO=>A_OUT);

BOUT: IOBUF port map (
I=>'0', O=>B_OUT_P, T=>CTRL_IN(2), IO=>B_OUT);

ZOUT: IOBUF port map (
I=>'0', O=>Z_OUT_P, T=>CTRL_IN(3), IO=>Z_OUT);

--CLK_IN: IOBUF port map (
--I=>CLK_IN_P, O=>open, T=>CTRL_IN(5), IO=>B_OUT);
--
--DATA_OUT: IOBUF port map (
--I=>'0', O=>DATA_OUT_P, T=>mux2(0), IO=>A_OUT);

end;
