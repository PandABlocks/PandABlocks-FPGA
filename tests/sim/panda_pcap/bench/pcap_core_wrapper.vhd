--------------------------------------------------------------------------------
--  File:       pcap_core_wrapper.vhd
--  Desc:       Position capture_i module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity pcap_core_wrapper is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block registers
    ARM                 : in  std_logic;
    DISARM              : in  std_logic;
    START_WRITE         : in  std_logic;
    WRITE               : in  std_logic_vector(31 downto 0);
    WRITE_WSTB          : in  std_logic;
    FRAMING_MASK        : in  std_logic_vector(31 downto 0);
    FRAMING_ENABLE      : in  std_logic;
    FRAMING_MODE        : in  std_logic_vector(31 downto 0);
    HEALTH              : out std_logic_vector(31 downto 0);
    -- Block inputs
    enable_i            : in  std_logic;
    capture_i           : in  std_logic;
    frame_i             : in  std_logic;
    dma_full_i          : in  std_logic;
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  std_logic_vector(32*32-1 downto 0);
    extbus_i            : in  std_logic_vector(32*12-1 downto 0);
    -- Block outputs
    pcap_dat_o          : out std_logic_vector(31 downto 0);
    pcap_dat_valid_o    : out std_logic;
    pcap_done_o         : out std_logic;
    pcap_actv_o         : out std_logic;
    pcap_status_o       : out std_logic_vector(2 downto 0)
);
end pcap_core_wrapper;

architecture rtl of pcap_core_wrapper is

signal posbus           : posbus_t;
signal extbus           : extbus_t;

begin

process(posbus_i) begin
    pos_bus: for i in 0 to 31 loop
        posbus(i) <= posbus_i(i*32+31 downto i*32);
    end loop;
end process;

process(extbus_i) begin
    ext_bus: for i in 0 to 11 loop
        extbus(i) <= extbus_i(i*32+31 downto i*32);
    end loop;
end process;


pcap_core_inst : entity work.pcap_core
port map (
    clk_i              =>  clk_i             ,
    reset_i            =>  reset_i           ,

    ARM                =>  ARM               ,
    DISARM             =>  DISARM            ,
    START_WRITE        =>  START_WRITE       ,
    WRITE              =>  WRITE             ,
    WRITE_WSTB         =>  WRITE_WSTB        ,
    FRAMING_MASK       =>  FRAMING_MASK      ,
    FRAMING_ENABLE     =>  FRAMING_ENABLE    ,
    FRAMING_MODE       =>  FRAMING_MODE      ,
    HEALTH             =>  HEALTH            ,
--    FRAME_NUM          => (others => '0'),

    enable_i           =>  enable_i          ,
    capture_i          =>  capture_i         ,
    frame_i            =>  frame_i           ,
--    dma_full_i         =>  dma_full_i        ,
    dma_error_i        => dma_full_i         ,
    sysbus_i           =>  sysbus_i          ,
    posbus_i           =>  posbus            ,
--    extbus_i           =>  extbus            ,

 --   dma_fifo_reset_o   =>  dma_fifo_reset_o  ,
    pcap_dat_o         =>  pcap_dat_o        ,
    pcap_dat_valid_o   =>  pcap_dat_valid_o  ,
    pcap_done_o        =>  pcap_done_o       ,
    pcap_actv_o        =>  pcap_actv_o       ,
    pcap_status_o      =>  pcap_status_o
);

end rtl;
