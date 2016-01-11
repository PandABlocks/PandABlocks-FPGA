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
    extbus_i            : in  extbus_t;
    -- Output pulses
    pcap_actv_o         : out std_logic;
    pcap_irq_o          : out std_logic
);
end panda_pcap_block;

architecture rtl of panda_pcap_block is

signal ENABLE_VAL       : std_logic_vector(SBUSBW-1 downto 0);
signal TRIGGER_VAL      : std_logic_vector(SBUSBW-1 downto 0);
signal TIMEOUT_VAL      : std_logic_vector(31 downto 0);
signal DMAADDR_WSTB     : std_logic;
signal DMAADDR          : std_logic_vector(31 downto 0);
signal IRQ_STATUS       : std_logic_vector(3 downto 0);
signal SMPL_COUNT       : std_logic_vector(31 downto 0);
signal CAPTURE_MASK     : std_logic_vector(46 downto 0);
signal FRAME_ENA        : std_logic_vector(31 downto 0);
signal BLOCK_SIZE       : std_logic_vector(31 downto 0);
signal ERR_STATUS       : std_logic_vector(31 downto 0) := (others => '0');
signal TRIG_MISSES      : unsigned(31 downto 0);

signal pcap_data_lt     : std32_array(46 downto 0);

signal soft_arm         : std_logic;
signal soft_disarm      : std_logic;
signal enable           : std_logic;
signal enable_prev      : std_logic;
signal enable_fall      : std_logic;
signal trigger          : std_logic;
signal trigger_prev     : std_logic;
signal trigger_rise     : std_logic;
signal soft_trigger     : std_logic := '0';

signal pcap_dat         : std_logic_vector(31 downto 0) := (others => '0');
signal pcap_wstb        : std_logic := '0';

signal INT_DISARM       : std_logic;

signal pcap_armed       : std_logic;
signal pcap_enabled     : std_logic;
signal pcap_disarmed    : std_logic_vector(1 downto 0);
signal ongoing_trigger  : std_logic;
signal pcap_fifo_rst    : std_logic := '0';

signal field_count      : integer range 0 to 47;

type pcap_fsm_t is (IDLE, ARMED, ENABLED, FINISH_TRIG);
signal pcap_fsm         : pcap_fsm_t;

begin

pcap_actv_o <= pcap_armed;

--
-- Control System Register Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ENABLE_VAL  <= TO_SVECTOR(0, SBUSBW);
            TRIGGER_VAL <= TO_SVECTOR(0, SBUSBW);
            DMAADDR_WSTB <= '0';
            DMAADDR <= (others => '0');
            SOFT_ARM <= '0';
            SOFT_DISARM <= '0';
            TIMEOUT_VAL <= TO_SVECTOR(0, 32);
            CAPTURE_MASK <= (others => '0');
            FRAME_ENA <= (others => '0');
            BLOCK_SIZE <= TO_SVECTOR(8192, 32);
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

                -- IRQ Timeout value
                if (mem_addr_i = PCAP_TIMEOUT_ADDR) then
                    TIMEOUT_VAL <= mem_dat_i;
                end if;

                -- DMA Soft Disarm
                if (mem_addr_i = PCAP_SOFT_DISARM_ADDR) then
                    SOFT_DISARM <= '1';
                end if;

                -- BitBus Capture Enable Mask
                if (mem_addr_i = PCAP_BITBUS_MASK_ADDR) then
                    CAPTURE_MASK(3 downto 0) <= mem_dat_i(3 downto 0);
                end if;

                -- Main PosBus Capture Enable Mask
                -- [0] is never captures.
                if (mem_addr_i = PCAP_CAPTURE_MASK_ADDR) then
                    CAPTURE_MASK(34 downto 4) <= mem_dat_i(31 downto 1);
                end if;

                -- Extended Values Capture Enable Mask
                if (mem_addr_i = PCAP_EXT_MASK_ADDR) then
                    -- Encoder extension
                    CAPTURE_MASK(38 downto 35) <= mem_dat_i(4 downto 1);
                    -- ADC extension
                    CAPTURE_MASK(46 downto 39) <= mem_dat_i(29 downto 22);
                end if;

                -- Framing Enable
                if (mem_addr_i = PCAP_FRAME_ENA_ADDR) then
                    FRAME_ENA <= mem_dat_i;
                end if;

                -- Host DMA Block memory size [in Bytes].
                if (mem_addr_i = PCAP_BLOCK_SIZE_ADDR) then
                    BLOCK_SIZE <= mem_dat_i;
                end if;

            end if;
        end if;
    end if;
end process;

REG_READ : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            mem_dat_o <= (others => '0');
        else
            case (mem_addr_i) is
                when PCAP_IRQ_STATUS_ADDR =>
                    mem_dat_o <= X"0000000" & IRQ_STATUS;
                when PCAP_SMPL_COUNT_ADDR =>
                    mem_dat_o <= SMPL_COUNT;
                when PCAP_TRIG_MISSES_ADDR =>
                    mem_dat_o <= std_logic_vector(TRIG_MISSES);
                when PCAP_ERR_STATUS_ADDR =>
                    mem_dat_o <= ERR_STATUS;
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
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
            pcap_disarmed <= "00";
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
                        pcap_disarmed(0) <= '0';
                        pcap_enabled <= '0';
                        pcap_fifo_rst <= '1';
                    end if;

                -- Wait for enable flag.
                when ARMED =>
                    pcap_fifo_rst <= '0';

                    if (SOFT_DISARM = '1') then
                        pcap_fsm <= IDLE;
                        pcap_armed <= '0';
                        pcap_disarmed(0) <= '1';
                        pcap_enabled <= '0';
                    elsif (enable = '1') then
                        pcap_fsm <= ENABLED;
                        pcap_enabled <= '1';
                    end if;

                -- Enabled until capture is finished or user disarm or
                -- missed trigger.
                when ENABLED =>
                    if (SOFT_DISARM = '1' or INT_DISARM = '1'
                            or enable_fall = '1') then
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
                        pcap_disarmed(0) <= '1';
                    end if;

                    if (INT_DISARM = '1') then
                        pcap_disarmed(1) <= '1';
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
enable <= SBIT(sysbus_i, ENABLE_VAL);

trigger <= SBIT(sysbus_i, TRIGGER_VAL);

--
-- Total number of fields that can be captured include Bit Bus, Position Bus
-- and Extended Bus.
--
-- CAPTURE_MASK register controls which fields are captured. So, on every
-- capture trigger, it takes 47 clock cycles to walk through the CAPTURE_MASK
-- register bit-by-bit to check whether the associated field is captured.
--
trigger_rise <= trigger and not trigger_prev;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            trigger_prev <= '0';
            ongoing_trigger <= '0';
            field_count <= 0;
            TRIG_MISSES <= (others => '0');
        else
            trigger_prev <= trigger;

            -- Latch all capture fields on rising edge of trigger only when
            -- position capture is enabled.
            if (trigger_rise = '1' and pcap_enabled = '1') then
                pcap_data_lt(0) <= sysbus_i(31 downto 0);
                pcap_data_lt(1) <= sysbus_i(63 downto 32);
                pcap_data_lt(2) <= sysbus_i(95 downto 64);
                pcap_data_lt(3) <= sysbus_i(127 downto 96);
                pcap_data_lt(34 downto 4) <= posbus_i(31 downto 1);
                pcap_data_lt(46 downto 35) <= extbus_i;
            end if;

            -- Walk CAPTURE_MASK register bit-by-bit on every trigger.
            if (trigger_rise = '1' and pcap_enabled = '1') then
                ongoing_trigger <= '1';
            elsif (field_count = 46) then
                ongoing_trigger <= '0';
            end if;

            -- Counter is active follwing trigger until all CAPTURE_MASK
            -- register is consumed.
            if (ongoing_trigger = '1') then
                field_count <= field_count + 1;
            else
                field_count <= 0;
            end if;

            -- Finally, generate pcap data and write strobe.
            if (ongoing_trigger = '1') then
                if (CAPTURE_MASK(field_count) = '1') then
                    pcap_dat <= pcap_data_lt(field_count);
                    pcap_wstb <= '1';
                else
                    pcap_wstb <= '0';
                end if;
            end if;

            -- Keep track of missed triggers.
            if (pcap_fsm = IDLE and SOFT_ARM = '1') then
                TRIG_MISSES <= (others => '0');
                INT_DISARM <= '0';
            elsif (ongoing_trigger = '1' and trigger_rise = '1') then
                TRIG_MISSES <= TRIG_MISSES + 1;
                INT_DISARM <= '1';
            end if;
        end if;
    end if;
end process;

ERR_STATUS(0) <= INT_DISARM;

--
-- Position Capture Core IP instantiation
--

panda_pcap_inst : entity work.panda_pcap
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enabled_i           => pcap_armed,
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
    BLOCK_SIZE          => BLOCK_SIZE,

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

