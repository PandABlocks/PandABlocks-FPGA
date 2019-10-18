library ieee;
use ieee.std_logic_1164.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity IDDR_sync_bit is
port (
    clk_i       : in std_logic;
    bit_i       : in std_logic;
    bit_o       : out std_logic
);
end entity;

architecture rtl of IDDR_sync_bit is

signal tied_to_ground : std_logic := '0';
signal tied_to_vcc    : std_logic := '1';

begin

IDDR_inst : IDDR
    generic map (
        DDR_CLK_EDGE => "SAME_EDGE_PIPELINED")
    port map (
        Q1 => bit_o,
        Q2 => open,
        C => clk_i,
        CE => tied_to_vcc,
        D => bit_i,
        R => tied_to_ground,
        S => tied_to_ground
);

end;
