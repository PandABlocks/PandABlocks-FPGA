--------------------------------------------------------------------------------
--  File:       pcomp_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity pcomp_block is
port (
    -- Clock and Reset.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface.
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Block Input and Outputs.
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    act_o               : out std_logic;
    pulse_o             : out std_logic;
    -- DMA Interface.
    dma_req_o           : out std_logic;
    dma_ack_i           : in  std_logic;
    dma_done_i          : in  std_logic;
    dma_addr_o          : out std_logic_vector(31 downto 0);
    dma_len_o           : out std_logic_vector(7 downto 0);
    dma_data_i          : in  std_logic_vector(31 downto 0);
    dma_valid_i         : in  std_logic
);
end pcomp_block;

architecture rtl of pcomp_block is

type state_t is (IDLE, POS, NEG);

signal ENABLE_VAL           : std_logic_vector(31 downto 0);
signal POSN_VAL             : std_logic_vector(31 downto 0);
signal START                : std_logic_vector(31 downto 0);
signal STEP                 : std_logic_vector(31 downto 0);
signal WIDTH                : std_logic_vector(31 downto 0);
signal NUM                  : std_logic_vector(31 downto 0);
signal RELATIVE             : std_logic_vector(31 downto 0);
signal DIR                  : std_logic_vector(31 downto 0);
signal DELTAP               : std_logic_vector(31 downto 0);
signal ERR                  : std_logic_vector(31 downto 0);
signal USE_TABLE            : std_logic_vector(31 downto 0);
signal TABLE_ADDRESS        : std_logic_vector(31 downto 0);
signal TABLE_LENGTH         : std_logic_vector(31 downto 0);
signal TABLE_LENGTH_WSTB    : std_logic;

signal pcomp_error          : std_logic_vector(31 downto 0);
signal TABLE_STATUS         : std_logic_vector(31 downto 0);

signal pulse                : std_logic;
signal enable               : std_logic;
signal posn                 : std_logic_vector(31 downto 0);

signal table_enable         : std_logic;
signal table_posn           : std_logic_vector(63 downto 0);
signal table_read           : std_logic;

begin

-- Assign outputs.
pulse_o <= pulse;

--
-- Control System Interface
--
pcomp_ctrl : entity work.pcomp_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,
    enable_o            => enable,
    inp_o               => posn,

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_dat_o,

    START               => START,
    START_WSTB          => open,
    STEP                => STEP,
    STEP_WSTB           => open,
    WIDTH               => WIDTH,
    WIDTH_WSTB          => open,
    PNUM                => NUM,
    PNUM_WSTB           => open,
    RELATIVE            => RELATIVE,
    RELATIVE_WSTB       => open,
    DIR                 => DIR,
    DIR_WSTB            => open,
    DELTAP              => DELTAP,
    DELTAP_WSTB         => open,
    USE_TABLE           => USE_TABLE,
    USE_TABLE_WSTB      => open,
    TABLE_ADDRESS       => TABLE_ADDRESS,
    TABLE_ADDRESS_WSTB  => open,
    TABLE_LENGTH        => TABLE_LENGTH,
    TABLE_LENGTH_WSTB   => TABLE_LENGTH_WSTB,
    ERROR               => pcomp_error,
    TABLE_STATUS        => TABLE_STATUS
);

--
-- Position Compare IP
--
pcomp_inst : entity work.pcomp
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enable_i            => enable,
    posn_i              => posn,
    table_posn_i        => table_posn,
    table_read_o        => table_read,

    START               => START,
    STEP                => STEP,
    WIDTH               => WIDTH,
    NUM                 => NUM,
    RELATIVE            => RELATIVE(0),
    DIR                 => DIR(0),
    DELTAP              => DELTAP,
    USE_TABLE           => USE_TABLE(0),

    act_o               => act_o,
    err_o               => pcomp_error,
    pulse_o             => pulse
);

--
-- Position Compare Long Table DMA Interfac
--

-- Pass enable signal if table is activated.
table_enable <= enable and USE_TABLE(0);

table_inst : entity work.pcomp_table
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enable_i            => table_enable,
    trig_i              => table_read,
    out_o               => table_posn,

    CYCLES              => TO_SVECTOR(1,32),
    TABLE_ADDR          => TABLE_ADDRESS,
    TABLE_LENGTH        => TABLE_LENGTH,
    TABLE_LENGTH_WSTB   => TABLE_LENGTH_WSTB,
    STATUS              => TABLE_STATUS,

    dma_req_o           => dma_req_o,
    dma_ack_i           => dma_ack_i,
    dma_done_i          => dma_done_i,
    dma_addr_o          => dma_addr_o,
    dma_len_o           => dma_len_o,
    dma_data_i          => dma_data_i,
    dma_valid_i         => dma_valid_i
);

end rtl;

