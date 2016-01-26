--------------------------------------------------------------------------------
--  File:       panda_pcap_top.vhd
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

entity panda_pcap_top is
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
    mem_cs_i            : in  std_logic_vector(2**PAGE_NUM-1 downto 0);
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_0_o         : out std_logic_vector(31 downto 0);
    mem_dat_1_o         : out std_logic_vector(31 downto 0);
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    extbus_i            : in  extbus_t;
    -- Output pulses
    pcap_actv_o         : out std_logic;
    pcap_irq_o          : out std_logic
);
end panda_pcap_top;

architecture rtl of panda_pcap_top is

type pcap_fsm_t is (IDLE, ARMED, ENABLED, FINISH_TRIG);
signal pcap_fsm         : pcap_fsm_t;

signal ENABLE_VAL       : std_logic_vector(SBUSBW-1 downto 0);
signal FRAME_VAL        : std_logic_vector(SBUSBW-1 downto 0);
signal CAPTURE_VAL      : std_logic_vector(SBUSBW-1 downto 0);
signal MISSED_CAPTURES  : unsigned(31 downto 0);
signal ERR_STATUS       : std_logic_vector(31 downto 0);

signal START_WRITE      : std_logic;
signal WRITE            : std_logic_vector(31 downto 0);
signal WRITE_WSTB       : std_logic;
signal FRAMING_MASK     : std_logic_vector(31 downto 0);
signal FRAMING_ENABLE   : std_logic;
signal ARM              : std_logic;
signal DISARM           : std_logic;

signal DMAADDR          : std_logic_vector(31 downto 0);
signal DMAADDR_WSTB     : std_logic;
signal BLOCK_SIZE       : std_logic_vector(31 downto 0);
signal TIMEOUT          : std_logic_vector(31 downto 0);
signal IRQ_STATUS       : std_logic_vector(3 downto 0);
signal SMPL_COUNT       : std_logic_vector(31 downto 0);

signal enable           : std_logic;
signal enable_prev      : std_logic;
signal enable_fall      : std_logic;
signal capture          : std_logic;
signal capture_prev     : std_logic;
signal capture_rise     : std_logic;
signal frame            : std_logic;

signal pcap_data_lt     : std32_array(46 downto 0);
signal pcap_dat         : std_logic_vector(31 downto 0) := (others => '0');
signal pcap_wstb        : std_logic := '0';

signal INT_DISARM       : std_logic;

signal pcap_armed       : std_logic;
signal pcap_enabled     : std_logic;
signal pcap_disarmed    : std_logic_vector(1 downto 0);
signal ongoing_capture  : std_logic;
signal pcap_fifo_rst    : std_logic := '0';

-- Mask BRAM signals
signal mask_length      : unsigned(5 downto 0);
signal mask_addra       : unsigned(5 downto 0);
signal mask_addrb       : unsigned(5 downto 0);
signal mask_doutb       : std_logic_vector(31 downto 0);

begin

-- Assign outputs.
pcap_actv_o <= pcap_armed;

-- Bitbus Assignments.
process(clk_i) begin
    if rising_edge(clk_i) then
        enable <= SBIT(sysbus_i, ENABLE_VAL);
        capture <= SBIT(sysbus_i, CAPTURE_VAL);
        frame <= SBIT(sysbus_i, FRAME_VAL);
    end if;
end process;

-- Detect rise/falling edge of internal signals.
enable_fall <= not enable and enable_prev;
capture_rise <= capture and not capture_prev;

--
-- Block Control Register Interface.
--
panda_pcap_ctrl_inst : entity work.panda_pcap_ctrl
port map (
    clk_i                   => clk_i,
    reset_i                 => reset_i,

    mem_cs_i                => mem_cs_i,
    mem_wstb_i              => mem_wstb_i,
    mem_addr_i              => mem_addr_i,
    mem_dat_i               => mem_dat_i,
    mem_dat_0_o             => mem_dat_0_o,
    mem_dat_1_o             => mem_dat_1_o,

    ENABLE                  => ENABLE_VAL,
    FRAME                   => FRAME_VAL,
    CAPTURE                 => CAPTURE_VAL,
    MISSED_CAPTURES         => std_logic_vector(MISSED_CAPTURES),
    ERR_STATUS              => ERR_STATUS,

    START_WRITE             => START_WRITE,
    WRITE                   => WRITE,
    WRITE_WSTB              => WRITE_WSTB,
    FRAMING_MASK            => FRAMING_MASK,
    FRAMING_ENABLE          => FRAMING_ENABLE,
    ARM                     => ARM,
    DISARM                  => DISARM,

    DMAADDR                 => DMAADDR,
    DMAADDR_WSTB            => DMAADDR_WSTB,
    BLOCK_SIZE              => BLOCK_SIZE,
    TIMEOUT                 => TIMEOUT,
    IRQ_STATUS(3 downto 0)  => IRQ_STATUS,
    IRQ_STATUS(31 downto 4) => (others => '0'),
    SMPL_COUNT              => SMPL_COUNT
);

--
-- Position Bus capture mask is implemented using a Block RAM to
-- achieve minimum dead time between capture triggers.
-- Data is pushed into the buffer sequentially followed by reset.
mask_spbram_inst : entity work.panda_spbram
generic map (
    AW          => 6,
    DW          => 32
)
port map (
    addra       => std_logic_vector(mask_addra),
    addrb       => std_logic_vector(mask_addrb),
    clka        => clk_i,
    clkb        => clk_i,
    dina        => WRITE,
    doutb       => mask_doutb,
    wea         => WRITE_WSTB
);

-- Fill mask buffer with capture indices sequentially, and
-- latch buffer length.
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            mask_length <= (others => '0');
            mask_addra <= (others => '0');
        else
            if (START_WRITE = '1') then
                mask_addra <= (others => '0');
            elsif (WRITE_WSTB = '1') then
                mask_addra <= mask_addra + 1;
            end if;

            if (pcap_fsm = ARMED and enable = '1') then
                mask_length <= mask_addra;
            end if;
        end if;
    end if;
end process;

--
-- Arm/Trigger/Disarm State Machine
--
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
                    if (ARM = '1') then
                        pcap_fsm <= ARMED;
                        pcap_armed <= '1';
                        pcap_disarmed(0) <= '0';
                        pcap_enabled <= '0';
                        pcap_fifo_rst <= '1';
                    end if;

                -- Wait for enable flag.
                when ARMED =>
                    pcap_fifo_rst <= '0';

                    if (DISARM = '1') then
                        pcap_fsm <= IDLE;
                        pcap_armed <= '0';
                        pcap_disarmed(0) <= '1';
                        pcap_enabled <= '0';
                    elsif (enable = '1') then
                        pcap_fsm <= ENABLED;
                        pcap_enabled <= '1';
                    end if;

                -- Enabled until capture is finished or user disarm or
                -- missed capture.
                when ENABLED =>
                    if (DISARM = '1' or INT_DISARM = '1'
                            or enable_fall = '1') then
                        -- Position bus is written sequentially into the
                        -- buffer and this takes 36 clock cycles for each
                        -- capture capture.
                        -- We must wait until all fields are written into the
                        -- buffer for proper finish.
                        if (ongoing_capture = '1') then
                            pcap_fsm <= FINISH_TRIG;
                        else
                            pcap_fsm <= IDLE;
                            pcap_armed <= '0';
                            pcap_enabled <= '0';
                        end if;
                    end if;

                    if (DISARM = '1') then
                        pcap_disarmed(0) <= '1';
                    end if;

                    if (INT_DISARM = '1') then
                        pcap_disarmed(1) <= '1';
                    end if;

                -- Wait for ongoing capture capture finish.
                when FINISH_TRIG =>
                    if (ongoing_capture = '0') then
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
--
--
pcap_dat <= pcap_data_lt(to_integer(mask_doutb));

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            capture_prev <= '0';
            ongoing_capture <= '0';
            mask_addrb <= (others => '0');
            MISSED_CAPTURES <= (others => '0');
            INT_DISARM <= '0';
            mask_addrb <= (others => '0');
        else
            capture_prev <= capture;

            -- Latch all capture fields on rising edge of capture only when
            -- position capture is enabled.
            if (capture_rise = '1' and pcap_enabled = '1') then
                pcap_data_lt(0) <= sysbus_i(31 downto 0);
                pcap_data_lt(1) <= sysbus_i(63 downto 32);
                pcap_data_lt(2) <= sysbus_i(95 downto 64);
                pcap_data_lt(3) <= sysbus_i(127 downto 96);
                pcap_data_lt(34 downto 4) <= posbus_i(31 downto 1);
                pcap_data_lt(46 downto 35) <= extbus_i;
            end if;

            -- Capture ongoing flag runs while mask buffer is read through.
            if (capture_rise = '1' and pcap_enabled = '1') then
                ongoing_capture <= '1';
            elsif (mask_addrb = mask_length - 1) then
                ongoing_capture <= '0';
            end if;

            -- Counter is active follwing capture until all CAPTURE_MASK
            -- register is consumed.
            if (ongoing_capture = '1') then
                mask_addrb <= mask_addrb + 1;
            else
                mask_addrb <= (others => '0');
            end if;

            -- Finally, generate pcap data and write strobe.
            if (ongoing_capture = '1') then
                pcap_wstb <= '1';
            else
                pcap_wstb <= '0';
            end if;

            -- Keep track of missed captures.
            if (pcap_fsm = IDLE and ARM = '1') then
                MISSED_CAPTURES <= (others => '0');
                INT_DISARM <= '0';
            elsif (ongoing_capture = '1' and capture_rise = '1') then
                MISSED_CAPTURES <= MISSED_CAPTURES + 1;
                INT_DISARM <= '1';
            end if;
        end if;
    end if;
end process;

ERR_STATUS(31 downto 1) <= (others => '0');
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

    DMAADDR             => DMAADDR,
    DMAADDR_WSTB        => DMAADDR_WSTB,
    TIMEOUT_VAL         => TIMEOUT,
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

