--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Infers user defined Dual-Port Block RAM
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spbram is
    generic (
        AW          : natural := 8;
        DW          : natural := 32
    );
    port (
        addra       : in  std_logic_vector(AW-1 downto 0);
        addrb       : in  std_logic_vector(AW-1 downto 0);
        clka        : in  std_logic;
        clkb        : in  std_logic;
        dina        : in  std_logic_vector(DW-1 downto 0);
        doutb       : out std_logic_vector(DW-1 downto 0);
        wea         : in  std_logic
    );
end spbram;

architecture rtl of spbram is

type mem_type is array (2**AW-1 downto 0) of std_logic_vector (DW-1 downto 0);
shared variable mem : mem_type := (others => (others => '0'));

begin

process (clka)
begin
   if (clka'event and clka = '1') then
     if (wea = '1') then
        mem(to_integer(unsigned(addra))) := dina;
     end if;
   end if;
end process;

process (clkb)
begin
   if (clkb'event and clkb = '1') then
     doutb <= mem(to_integer(unsigned(addrb)));
   end if;
end process;

end rtl;

