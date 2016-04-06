LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

library unisim;
use unisim.vcomponents.all;

entity daughter_card_model is
port (
    -- Front Panel via DB15
    A_IN_P      : in    std_logic;
    B_IN_P      : in    std_logic;
    Z_IN_P      : in    std_logic;
    CLK_OUT_P   : inout std_logic;
    DATA_IN_P   : inout std_logic;

    A_OUT_P     : out   std_logic;
    B_OUT_P     : out   std_logic;
    Z_OUT_P     : out   std_logic;
    CLK_IN_P    : inout std_logic;
    DATA_OUT_P  : inout std_logic;

    -- FMC Interface
    A_IN        : inout  std_logic;
    B_IN        : inout  std_logic;
    Z_IN        : inout  std_logic;

    A_OUT       : inout std_logic;
    B_OUT       : inout std_logic;
    Z_OUT       : inout std_logic;

    DCARD_MODE  : in    std_logic_vector(3 downto 0);
    DCARD_CTRL  : inout std_logic_vector(15 downto 0)
);
end daughter_card_model;

architecture behavior of daughter_card_model is

signal CTRL_IN      : std_logic_vector(11 downto 0);
signal mux1         : std_logic_vector(1 downto 0);
signal mux2         : std_logic_vector(1 downto 0);

begin

CTRL_IN <= DCARD_CTRL(11 downto 0);
DCARD_CTRL(15 downto 12) <= DCARD_MODE;

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


SN75LBC175A_inst : entity work.SN75LBC175A
port map (
    Y1     => A_IN,
    Y2     => B_IN,
    Y3     => Z_IN,
    Y4     => open,

    A1     => A_IN_P,
    A2     => B_IN_P,
    A3     => Z_IN_P,
    A4     => '0',

    EN12    => CTRL_IN(0),
    EN34    => CTRL_IN(1)
);

SN75LBC174A_inst : entity work.SN75LBC174A
port map (
    A1     => A_OUT,
    A2     => B_OUT,
    A3     => Z_OUT,
    A4     => open,

    Y1     => A_OUT_P,
    Y2     => B_OUT_P,
    Y3     => Z_OUT_P,
    Y4     => open,

    EN12    => CTRL_IN(2),
    EN34    => CTRL_IN(3)
);

SN65HVD05D_u10 : entity work.SN65HVD05D
port map (
    A       => DATA_IN_P,

    R       => A_IN,
    REn     => mux1(1),
    DE      => mux1(0),
    D       => A_IN
);

SN65HVD05D_u12 : entity work.SN65HVD05D
port map (
    A       => CLK_OUT_P,

    R       => open,
    REn     => '1',
    DE      => CTRL_IN(4),
    D       => B_IN
);

SN65HVD05D_u15 : entity work.SN65HVD05D
port map (
    A       => DATA_OUT_P,

    R       => A_OUT,
    REn     => mux2(1),
    DE      => mux2(0),
    D       => A_OUT
);

SN65HVD05D_u16 : entity work.SN65HVD05D
port map (
    A       => CLK_IN_P,

    R       => B_OUT,
    REn     => CTRL_IN(5),
    DE      => '0',
    D       => open
);

end;
