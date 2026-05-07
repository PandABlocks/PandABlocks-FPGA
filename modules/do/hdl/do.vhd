library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;

entity do is
    port (
        clk_i : in  std_logic;
        -- IO pad
        pad_o : out std_logic;
        -- Block Input and Outputs
        val_i : in std_logic
    );
end;

architecture rtl of do is
begin
    pad_o <= val_i;
end;
