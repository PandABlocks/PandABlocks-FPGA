--------------------------------------------------------------------------------
--  File:       panda_pcap_block.vhd
--  Desc:       Position capture module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_pcap_block is
generic (
    AXI_BURST_LEN       : integer := 16;
    AXI_ADDR_WIDTH      : integer := 32;
    AXI_DATA_WIDTH      : integer := 32
);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- AXI3 HP Bus Write Only Interface
    m_axi_awready       : in  std_logic;
    m_axi_awaddr        : out std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    m_axi_awvalid       : out std_logic;
    m_axi_awburst       : out std_logic_vector(1 downto 0);
    m_axi_awcache       : out std_logic_vector(3 downto 0);
    m_axi_awid          : out std_logic_vector(5 downto 0);
    m_axi_awlen         : out std_logic_vector(3 downto 0);
    m_axi_awlock        : out std_logic_vector(1 downto 0);
    m_axi_awprot        : out std_logic_vector(2 downto 0);
    m_axi_awqos         : out std_logic_vector(3 downto 0);
    m_axi_awsize        : out std_logic_vector(2 downto 0);
    m_axi_bid           : in  std_logic_vector(5 downto 0);
    m_axi_bready        : out std_logic;
    m_axi_bresp         : in  std_logic_vector(1 downto 0);
    m_axi_bvalid        : in  std_logic;
    m_axi_wready        : in  std_logic;
    m_axi_wdata         : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    m_axi_wvalid        : out std_logic;
    m_axi_wlast         : out std_logic;
    m_axi_wstrb         : out std_logic_vector(AXI_DATA_WIDTH/8-1 downto 0);
    m_axi_wid           : out std_logic_vector(5 downto 0);
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    pcap_irq_o          : out std_logic
    -- Output pulse
);
end panda_pcap_block;

architecture rtl of panda_pcap_block is

signal ENABLE_VAL       : std_logic_vector(SBUSBW-1 downto 0);
signal TRIGGER_VAL      : std_logic_vector(SBUSBW-1 downto 0);
signal TIMEOUT_VAL      : std_logic_vector(31 downto 0);
signal DMAADDR_WSTB     : std_logic;
signal DMAADDR          : std_logic_vector(31 downto 0);
signal SOFT_ENABLE      : std_logic;
signal IRQ_STATUS       : std_logic_vector(3 downto 0);
signal SMPL_COUNT       : std_logic_vector(31 downto 0);

signal soft_arm         : std_logic;
signal soft_disarm      : std_logic;
signal enable           : std_logic;
signal enable_prev      : std_logic;
signal enable_fall      : std_logic;
signal trigger          : std_logic;
signal soft_trigger     : std_logic := '0';

signal pcap_dat         : std_logic_vector(31 downto 0) := (others => '0');
signal pcap_wstb        : std_logic := '0';


signal pcap_armed       : std_logic;
signal pcap_enabled     : std_logic;
signal pcap_disarmed    : std_logic;
signal ongoing_trigger  : std_logic := '0';
signal pcap_fifo_rst    : std_logic := '0';

type pcap_fsm_t is (IDLE, ARMED, ENABLED, FINISH_TRIG);
signal pcap_fsm         : pcap_fsm_t;

begin

mem_dat_o <= (others => '0');

--
-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ENABLE_VAL  <= TO_SVECTOR(0, SBUSBW);
            TRIGGER_VAL <= TO_SVECTOR(0, SBUSBW);
            DMAADDR_WSTB <= '0';
            DMAADDR <= (others => '0');
            SOFT_ENABLE <= '0';
            SOFT_ARM <= '0';
            SOFT_DISARM <= '0';
            TIMEOUT_VAL <= TO_SVECTOR(0, 32);
        else
            -- Single clock pulse
            SOFT_ARM <= '0';
            SOFT_DISARM <= '0';
            DMAADDR_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Pulse start position
                if (mem_addr_i = PCAP_ENABLE_VAL_ADDR) then
                    ENABLE_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Pulse start position
                if (mem_addr_i = PCAP_TRIGGER_VAL_ADDR) then
                    TRIGGER_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- DMA block Soft ARM
                if (mem_addr_i = PCAP_SOFT_ARM_ADDR) then
                    SOFT_ARM <= '1';
                end if;

                -- DMA block address
                if (mem_addr_i = PCAP_DMAADDR_ADDR) then
                    DMAADDR <= mem_dat_i;
                    DMAADDR_WSTB <= '1';
                end if;

                -- Position Field Mask
                if (mem_addr_i = PCAP_TIMEOUT_ADDR) then
                    TIMEOUT_VAL <= mem_dat_i;
                end if;


                -- DMA block Soft ARM
                if (mem_addr_i = PCAP_SOFT_DISARM_ADDR) then
                    SOFT_DISARM <= '1';
                end if;

                -- Software User Flags
                if (mem_addr_i = PCAP_SOFT_ENABLE_ADDR) then
                    SOFT_ENABLE <= mem_dat_i(0);
                end if;
            end if;
        end if;
    end if;
end process;

--
-- Arm/Trigger/Disarm State Machine
--
enable_fall <= not enable and enable_prev;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            pcap_armed <= '0';
            pcap_disarmed <= '0';
            pcap_enabled <= '0';
            pcap_fsm <= IDLE;
            enable_prev <= '0';
            pcap_fifo_rst <= '0';
        else
            enable_prev <= enable;

            case (pcap_fsm) is
                -- Wait for user arm.
                when IDLE =>
                    if (SOFT_ARM = '1') then
                        pcap_fsm <= ARMED;
                        pcap_armed <= '1';
                        pcap_disarmed <= '0';
                        pcap_enabled <= '1';
                        pcap_fifo_rst <= '1';
                    end if;
                -- Wait for enable flag.
                when ARMED =>
                    pcap_fifo_rst <= '0';

                    if (SOFT_DISARM = '1') then
                        pcap_fsm <= IDLE;
                        pcap_armed <= '0';
                        pcap_disarmed <= '1';
                        pcap_enabled <= '0';
                    elsif (enable = '1') then
                        pcap_fsm <= ENABLED;
                    end if;
                -- Enabled until capture is finished or user disarm.
                when ENABLED =>
                    if (SOFT_DISARM = '1' or enable_fall = '1') then
                        -- Position bus is written sequentially into the
                        -- buffer and this takes 36 clock cycles for each
                        -- capture trigger.
                        -- We must wait until all fields are written into the
                        -- buffer for proper finish.
                        if (ongoing_trigger = '1') then
                            pcap_fsm <= FINISH_TRIG;
                        else
                            pcap_fsm <= IDLE;
                            pcap_armed <= '0';
                            pcap_enabled <= '0';
                        end if;
                    end if;

                    if (SOFT_DISARM = '1') then
                        pcap_disarmed <= '1';
                    end if;
                -- Wait for ongoing trigger capture finish.
                when FINISH_TRIG =>
                    if (ongoing_trigger = '0') then
                        pcap_fsm <= IDLE;
                        pcap_armed <= '0';
                        pcap_enabled <= '0';
                    end if;

                when others =>
                    pcap_fsm <= IDLE;
            end case;
        end if;
    end if;
end process;

--
-- Design Bus Assignments
--
enable <= SOFT_ENABLE when (SOFT_ENABLE = '1')
                else SBIT(sysbus_i, ENABLE_VAL);

trigger <= soft_trigger when (SOFT_ENABLE = '1')
                else SBIT(sysbus_i, TRIGGER_VAL);

pcap_wstb <= trigger and pcap_enabled;
pcap_dat <= posbus_i(0);

panda_pcap_inst : entity work.panda_pcap
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enabled_i           => pcap_enabled,
    disarmed_i          => pcap_disarmed,
    pcap_frst_i         => pcap_fifo_rst,
    pcap_dat_i          => pcap_dat,
    pcap_wstb_i         => pcap_wstb,
    irq_o               => pcap_irq_o,

    TIMEOUT_VAL         => TIMEOUT_VAL,
    DMAADDR             => DMAADDR,
    DMAADDR_WSTB        => DMAADDR_WSTB,
    IRQ_STATUS          => IRQ_STATUS,
    SMPL_COUNT          => SMPL_COUNT,

    m_axi_awready       => m_axi_awready,
    m_axi_awaddr        => m_axi_awaddr,
    m_axi_awvalid       => m_axi_awvalid,
    m_axi_awburst       => m_axi_awburst,
    m_axi_awcache       => m_axi_awcache,
    m_axi_awid          => m_axi_awid,
    m_axi_awlen         => m_axi_awlen,
    m_axi_awlock        => m_axi_awlock,
    m_axi_awprot        => m_axi_awprot,
    m_axi_awqos         => m_axi_awqos,
    m_axi_awsize        => m_axi_awsize,
    m_axi_bid           => m_axi_bid,
    m_axi_bready        => m_axi_bready,
    m_axi_bresp         => m_axi_bresp,
    m_axi_bvalid        => m_axi_bvalid,
    m_axi_wready        => m_axi_wready,
    m_axi_wdata         => m_axi_wdata,
    m_axi_wvalid        => m_axi_wvalid,
    m_axi_wlast         => m_axi_wlast,
    m_axi_wstrb         => m_axi_wstrb,
    m_axi_wid           => m_axi_wid
);

end rtl;

