library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package reg_defines is

-- REG Block:
constant REG_FPGA_VERSION : natural := 0;
constant REG_FPGA_BUILD : natural := 1;
constant REG_USER_VERSION : natural := 2;
constant REG_BIT_READ_RST : natural := 3;
constant REG_BIT_READ_VALUE : natural := 4;
constant REG_POS_READ_RST : natural := 5;
constant REG_POS_READ_VALUE : natural := 6;
constant REG_POS_READ_CHANGES : natural := 7;
constant REG_PCAP_START_WRITE : natural := 8;
constant REG_PCAP_WRITE : natural := 9;
constant REG_PCAP_ARM : natural := 13;
constant REG_PCAP_DISARM : natural := 14;
constant REG_PCAP_DATA_DELAY_0 : natural := 32;
constant REG_PCAP_DATA_DELAY_1 : natural := 33;
constant REG_PCAP_DATA_DELAY_2 : natural := 34;
constant REG_PCAP_DATA_DELAY_3 : natural := 35;
constant REG_PCAP_DATA_DELAY_4 : natural := 36;
constant REG_PCAP_DATA_DELAY_5 : natural := 37;
constant REG_PCAP_DATA_DELAY_6 : natural := 38;
constant REG_PCAP_DATA_DELAY_7 : natural := 39;
constant REG_PCAP_DATA_DELAY_8 : natural := 40;
constant REG_PCAP_DATA_DELAY_9 : natural := 41;
constant REG_PCAP_DATA_DELAY_10 : natural := 42;
constant REG_PCAP_DATA_DELAY_11 : natural := 43;
constant REG_PCAP_DATA_DELAY_12 : natural := 44;
constant REG_PCAP_DATA_DELAY_13 : natural := 45;
constant REG_PCAP_DATA_DELAY_14 : natural := 46;
constant REG_PCAP_DATA_DELAY_15 : natural := 47;
constant REG_PCAP_DATA_DELAY_16 : natural := 48;
constant REG_PCAP_DATA_DELAY_17 : natural := 49;
constant REG_PCAP_DATA_DELAY_18 : natural := 50;
constant REG_PCAP_DATA_DELAY_19 : natural := 51;
constant REG_PCAP_DATA_DELAY_20 : natural := 52;
constant REG_PCAP_DATA_DELAY_21 : natural := 53;
constant REG_PCAP_DATA_DELAY_22 : natural := 54;
constant REG_PCAP_DATA_DELAY_23 : natural := 55;
constant REG_PCAP_DATA_DELAY_24 : natural := 56;
constant REG_PCAP_DATA_DELAY_25 : natural := 57;
constant REG_PCAP_DATA_DELAY_26 : natural := 58;
constant REG_PCAP_DATA_DELAY_27 : natural := 59;
constant REG_PCAP_DATA_DELAY_28 : natural := 60;
constant REG_PCAP_DATA_DELAY_29 : natural := 61;
constant REG_PCAP_DATA_DELAY_30 : natural := 62;
constant REG_PCAP_DATA_DELAY_31 : natural := 63;

-- DRV Block:
constant DRV_PCAP_DMA_RESET : natural := 0;
constant DRV_PCAP_DMA_START : natural := 1;
constant DRV_PCAP_DMA_ADDR : natural := 2;
constant DRV_PCAP_TIMEOUT : natural := 3;
constant DRV_PCAP_IRQ_STATUS : natural := 4;
constant DRV_PCAP_BLOCK_SIZE : natural := 6;

end reg_defines;

package body reg_defines is


end reg_defines;