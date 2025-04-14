library ieee;
use ieee.std_logic_1164.all;

package top_defines_gen is

--------------------------------------------------------------------------
-- !!! Remember to add aliases for any new entities here to top_defines
--------------------------------------------------------------------------

-- Bit Bus Width, Multiplexer Select Width -------------------------------
constant BBUSW                  : natural := 128;
constant BBUSBW                 : natural := 7;

-- Position Bus Width, Multiplexer Select Width.
constant PBUSW                  : natural := 18;
constant PBUSBW                 : natural := 5;

-- Extended Position Bus Width.
constant EBUSW                  : natural := 12;
--------------------------------------------------------------------------

-- FPGA options
constant PCAP_STD_DEV_OPTION : std_logic := '1';
constant FINE_DELAY_OPTION : std_logic := '1';
constant PICXO_OPTION : std_logic := '1';

end top_defines_gen;
