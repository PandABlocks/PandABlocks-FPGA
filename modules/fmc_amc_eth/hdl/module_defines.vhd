library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package module_defines is

type Eth_phy2clk_interface is
  record
    txoutclk             : std_logic;
    rxoutclk             : std_logic;
    mmcm_reset           : std_logic;
end record Eth_phy2clk_interface;

type Eth_clk2phy_interface is
  record
    gtrefclk_bufg        : std_logic;
    mmcm_locked          : std_logic;
    userclk              : std_logic;
    userclk2             : std_logic;
    rxuserclk            : std_logic;
    rxuserclk2           : std_logic;
    qplloutclk           : std_logic;
    qplloutrefclk        : std_logic;
end record Eth_clk2phy_interface;

end module_defines;