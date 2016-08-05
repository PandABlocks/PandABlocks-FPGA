library ieee;
use ieee.std_logic_1164.all;
package panda_version is
constant FPGA_VERSION: std_logic_vector(31 downto 0)   := X"05081602";
constant FPGA_BUILD: std_logic_vector(31 downto 0)   := X"05081602";
end panda_version;
