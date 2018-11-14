---------------------------------------------------------------------------------------
--! @file
--! @brief    Local Types for the ACQ427FMC
--! @author   John McLean
--! @date     14th June 2017
--! @details
--! D-TACQ Solutions Ltd Copyright 2013-2018
--!

--! Standard Libraries - numeric.std for all designs
library ieee;
use ieee.std_logic_1164.all; -- Standard Logic Functions
use ieee.numeric_std.all;    -- Numeric Functions for Signed / Unsigned Arithmetic

--! Xilinx Primitive Library
library UNISIM;
use UNISIM.VComponents.all;		-- Xilinx Primitives

package ACQ427TYPES is

constant c_MODULE_TYPE      : std_logic_vector( 7 downto  0) := x"07";  -- ! This is the definition of the module
constant c_MODULE_TYPE_FAST : std_logic_vector( 7 downto  0) := x"A7";  -- ! This is the definition of the module
constant c_MODULE_VERSION   : std_logic_vector( 7 downto  0) := x"00";
constant c_FPGA_REVISION    : std_logic_vector(15 downto  0) := x"0001";

--! This is the array of Registers  used as a structure for ease of VHDL entity and instantiation definition
type REG_ARRAY is array(15 downto 0) of std_logic_vector(31 downto 0);

end package ACQ427TYPES;
