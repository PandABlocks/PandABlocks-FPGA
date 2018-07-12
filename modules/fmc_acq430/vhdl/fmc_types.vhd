---------------------------------------------------------------------------------------
--! @file
--! @brief    Local Types for the ACQ430FMC
--! @author   John McLean
--! @date     10th March 2016
--! @details                                                                                                                    \n
--! D-TACQ Solutions Ltd Copyright 2014-2017                                                                    \n
--!                                                                                                                             \n

--! Standard Libraries - numeric.std for all designs
library ieee;
use ieee.std_logic_1164.all;            --! Standard Logic Functions
use ieee.numeric_std.all;               --! Numeric Functions for Signed / Unsigned Arithmetic

--! If using Xilinx primitives need the Xilinx library
library UNISIM;
use UNISIM.VComponents.all;             --! Xilinx Primitives

package ACQ430TYPES is


constant c_MODULE_TYPE                                  :std_logic_vector( 7 downto  0) := x"03";       -- ! This is the definition of the module
constant c_MODULE_VERSION_MASTER                        : std_logic_vector( 3 downto  0)        := x"0";
constant c_MODULE_VERSION_SLAVE                 : std_logic_vector( 3 downto  0)        := x"8";
constant c_FPGA_REVISION                                        :std_logic_vector(15 downto  0) := x"0017";


--ACQ430 FIFO Read Data Alias
constant c_REGISTER_BOTTOM:                             std_logic_vector (15 downto 0)  := x"0000";
constant c_REGISTER_TOP:                                std_logic_vector (15 downto 0)  := x"1000";

--ACQ430 Threshold RAM Address Alias
constant c_THRESHOLD_REGISTER:                  std_logic_vector (15 downto 0)  := x"e000";


-- Converter Characteristics - ###############################################  SYNTHESIS  ##########################################################
constant c_GROUP_DELAY_HI_RES           : unsigned (7 downto 0) := x"27";               --! ADS1278 Filter Group Delay in High Speed mode = 39
constant c_GROUP_DELAY_HI_SPEED : unsigned (7 downto 0) := x"26";               --! ADS1278 Filter Group Delay in High Speed mode = 38
constant c_TRIGGER_DELAY_HI_RES : unsigned (7 downto 0) := x"29";               --! ADS1278 Filter Group Delay in High Speed mode = 39
constant c_TRIGGER_DELAY_HI_SPEED       : unsigned (7 downto 0) := x"28";               --! ADS1278 Filter Group Delay in High Speed mode = 38
constant c_SYNC_TIME_MASTER             :       unsigned( 7 downto 0) := "11111111";            --! Number of Conversions before Valid Data this is 128 conversions
constant c_SYNC_TIME_SLAVE              :       unsigned( 7 downto 0) := "11111100";            --! Number of Conversions before Valid Data this is 128 conversions


constant c_HIGH_SPEED_DIVIDE            : unsigned( 8 downto 0) := '0' & x"ff";         --! Divide by 256 when in High Speed Mode
constant c_HIGH_RES_DIVIDE              : unsigned( 8 downto 0) := '1' & x"ff";         --! Divide by 512 when in High Resolution Mode


-- AXI Burst Types
constant c_AXI_BURST_FIXED                                      : std_logic_vector(1 downto 0)  := "00";
constant c_AXI_BURST_INCR                                       : std_logic_vector(1 downto 0)  := "01";
constant c_AXI_BURST_WRAP                                       : std_logic_vector(1 downto 0)  := "10";
constant c_AXI_BURST_RESERVED                                   : std_logic_vector(1 downto 0)  := "11";


--! This is the array of Registers  used as a structure for ease of VHDL entity and instantiation definition
type REG_ARRAY is array(15 downto 0) of std_logic_vector(31 downto 0);




end package ACQ430TYPES;
