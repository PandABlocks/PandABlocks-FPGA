--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : FMC 24VIO module interface
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity fmc_24vio is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- FMC LA I/O
    FMC_LA_P            : inout std_logic_vector(33 downto 0);
    FMC_LA_N            : inout std_logic_vector(33 downto 0);
    -- 24VIO Inteface
    fmc_in_o            : out std_logic_vector(7 downto 0);
    fmc_out_i           : in  std_logic_vector(7 downto 0)
);
end fmc_24vio;

architecture rtl of fmc_24vio is

begin

-- Outputs going to FMC connector
fmc_in_o(0) <= FMC_LA_P(0);
fmc_in_o(1) <= FMC_LA_N(0);
fmc_in_o(2) <= FMC_LA_P(1);
fmc_in_o(3) <= FMC_LA_N(1);
fmc_in_o(4) <= FMC_LA_P(2);
fmc_in_o(5) <= FMC_LA_N(2);
fmc_in_o(6) <= FMC_LA_P(3);
fmc_in_o(7) <= FMC_LA_N(3);

-- Inputs output towards FMC connector
FMC_LA_P(4) <= fmc_out_i(0);
FMC_LA_N(4) <= fmc_out_i(1);
FMC_LA_P(5) <= fmc_out_i(2);
FMC_LA_N(5) <= fmc_out_i(3);
FMC_LA_P(6) <= fmc_out_i(4);
FMC_LA_N(6) <= fmc_out_i(5);
FMC_LA_P(7) <= fmc_out_i(6);
FMC_LA_N(7) <= fmc_out_i(7);

-- Unused IO
FMC_LA_P(33 downto 8) <= (others => 'Z');
FMC_LA_N(33 downto 8) <= (others => 'Z');

end rtl;

