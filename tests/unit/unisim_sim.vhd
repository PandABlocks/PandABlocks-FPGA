--------------------------------------------------------------------------------
--  PandA Motion Project
--      Diamond Light Source, Oxford, UK
--------------------------------------------------------------------------------
--
--  Description : Behavioural stand-ins for the Xilinx unisim primitives used
--                by entities under test in tests/unit. entity_runner compiles
--                this file into a library named unisim so the entities
--                simulate unchanged.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package vcomponents is

component IOBUF is
port (
    O   : out   std_ulogic;
    IO  : inout std_ulogic;
    I   : in    std_ulogic;
    T   : in    std_ulogic
);
end component IOBUF;

end package;


-- Bidirectional buffer, drives the pad with I while T is low and always
-- reads the pad back on O
library ieee;
use ieee.std_logic_1164.all;

entity IOBUF is
port (
    O   : out   std_ulogic;
    IO  : inout std_ulogic;
    I   : in    std_ulogic;
    T   : in    std_ulogic
);
end;

architecture sim of IOBUF is
begin
    IO <= I when T = '0' else 'Z';
    O <= IO;
end;
