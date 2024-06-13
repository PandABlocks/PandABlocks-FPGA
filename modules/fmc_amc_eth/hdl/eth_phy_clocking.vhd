------------------------------------------------------------------------------------
--  NAMC - 2020
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Shu ZHANG & Arthur MARIANO
-----------------------------------------------------------------------------------
--
--  Description : This module holds the Clocking logic for eth_phy core.
--
------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.module_defines.all;

entity eth_phy_clocking is
port (
      clk_i                   : in  std_logic; 
      pma_reset_i             : in  std_logic; 
      gtrefclk_i              : in  std_logic; -- Reference clock for MGT
      eth_phy_clk_i           : in  Eth_phy2clk_interface;
      eth_phy_clk_o           : out Eth_clk2phy_interface
);
end eth_phy_clocking;

architecture rtl of eth_phy_clocking is

component gig_ethernet_pcs_pma_0_gt_common
  port(
    GTREFCLK0_IN         : in std_logic;
    QPLLLOCK_OUT         : out std_logic;
    QPLLLOCKDETCLK_IN    : in std_logic;
    QPLLOUTCLK_OUT       : out std_logic;
    QPLLOUTREFCLK_OUT    : out std_logic;
    QPLLREFCLKLOST_OUT   : out std_logic;
    QPLLRESET_IN         : in std_logic
  );
end component;

component gig_ethernet_pcs_pma_0_clocking
   port (
      gtrefclk                : in  std_logic;                -- Reference clock for MGT
      txoutclk                : in  std_logic;                -- txoutclk from GT transceiver.
      rxoutclk                : in  std_logic;                -- txoutclk from GT transceiver.
      mmcm_reset              : in  std_logic;                -- MMCM Reset
      gtrefclk_bufg           : out std_logic;
      mmcm_locked             : out std_logic;                -- MMCM locked
      userclk                 : out std_logic;                -- for GT PMA reference clock
      userclk2                : out std_logic;
      rxuserclk               : out std_logic;                -- for GT PMA reference clock
      rxuserclk2              : out std_logic
   );
end component;

begin

core_gt_common_i : gig_ethernet_pcs_pma_0_gt_common
  port map(
    GTREFCLK0_IN              => gtrefclk_i,
    QPLLLOCK_OUT              => open,
    QPLLLOCKDETCLK_IN         => clk_i,
    QPLLOUTCLK_OUT            => eth_phy_clk_o.qplloutclk,
    QPLLOUTREFCLK_OUT         => eth_phy_clk_o.qplloutrefclk,
    QPLLREFCLKLOST_OUT        => open,
    QPLLRESET_IN              => pma_reset_i
    );

core_clocking_i : gig_ethernet_pcs_pma_0_clocking
  port map(
    gtrefclk                => gtrefclk_i,
    txoutclk                => eth_phy_clk_i.txoutclk,
    rxoutclk                => eth_phy_clk_i.rxoutclk,
    mmcm_reset              => eth_phy_clk_i.mmcm_reset,
    gtrefclk_bufg           => eth_phy_clk_o.gtrefclk_bufg,
    mmcm_locked             => eth_phy_clk_o.mmcm_locked,
    userclk                 => eth_phy_clk_o.userclk,
    userclk2                => eth_phy_clk_o.userclk2,
    rxuserclk               => eth_phy_clk_o.rxuserclk,
    rxuserclk2              => eth_phy_clk_o.rxuserclk2
    );
    

end rtl;

