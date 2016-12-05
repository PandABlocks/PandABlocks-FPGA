--------------------------------------------------------------------------------
--  File:       pcomp_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity pcomp_block is
generic (
    INST                : natural := 0
);
port (
    -- Clock and Reset.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(BLK_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(BLK_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- Block Input and Outputs.
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    act_o               : out std_logic;
    out_o               : out std_logic;
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

component ila_128x8K
port (
    clk                     : in  std_logic;
    probe0                  : in  std_logic_vector(15 downto 0);
    probe1                  : in  std_logic_vector(15 downto 0);
    probe2                  : in  std_logic_vector(15 downto 0);
    probe3                  : in  std_logic_vector(15 downto 0);
    probe4                  : in  std_logic_vector(15 downto 0);
    probe5                  : in  std_logic_vector(31 downto 0);
    probe6                  : in  std_logic_vector(31 downto 0);
    probe7                  : in  std_logic_vector(7 downto 0)
);
end component;

signal probe0               : std_logic_vector(15 downto 0);
signal probe1               : std_logic_vector(15 downto 0);
signal probe2               : std_logic_vector(15 downto 0);
signal probe3               : std_logic_vector(15 downto 0);
signal probe4               : std_logic_vector(15 downto 0);
signal probe5               : std_logic_vector(31 downto 0);
signal probe6               : std_logic_vector(31 downto 0);
signal probe7               : std_logic_vector(7 downto 0);

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

signal pcomp_act            : std_logic;
signal pcomp_out            : std_logic;
signal pcomp_error          : std_logic_vector(31 downto 0);
signal TABLE_STATUS         : std_logic_vector(31 downto 0);

signal enable               : std_logic;
signal posn                 : std_logic_vector(31 downto 0);

signal table_enable         : std_logic;
signal table_posn           : std_logic_vector(63 downto 0);
signal table_read           : std_logic;
signal table_end            : std_logic;

attribute MARK_DEBUG            : string;
attribute MARK_DEBUG of probe0  : signal is "true";
attribute MARK_DEBUG of probe1  : signal is "true";
attribute MARK_DEBUG of probe2  : signal is "true";
attribute MARK_DEBUG of probe3  : signal is "true";
attribute MARK_DEBUG of probe4  : signal is "true";
attribute MARK_DEBUG of probe5  : signal is "true";
attribute MARK_DEBUG of probe6  : signal is "true";
attribute MARK_DEBUG of probe7  : signal is "true";

begin

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

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

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
    table_end_i         => table_end,

    START               => START,
    STEP                => STEP,
    WIDTH               => WIDTH,
    NUM                 => NUM,
    RELATIVE            => RELATIVE(0),
    DIR                 => DIR(0),
    DELTAP              => DELTAP,
    USE_TABLE           => USE_TABLE(0),

    act_o               => pcomp_act,
    err_o               => pcomp_error,
    out_o               => pcomp_out
);

act_o <= pcomp_act;
out_o <= pcomp_out;

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
    table_end_o         => table_end,

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

--ILA_INST : IF (INST = 0) GENERATE
--
--ila_128x8K_inst : ila_128x8K
--port map (
--    clk                 => clk_i,
--    probe0              => probe0,
--    probe1              => probe1,
--    probe2              => probe2,
--    probe3              => probe3,
--    probe4              => probe4,
--    probe5              => probe5,
--    probe6              => probe6,
--    probe7              => probe7
--);
--
--probe0              <= START(15 downto 0);
--probe1              <= STEP(15 downto 0);
--probe2              <= WIDTH(15 downto 0);
--probe3              <= DELTAP(15 downto 0);
--probe4              <= NUM(15 downto 0);
--probe5              <= posn(31 downto 0);
--probe6              <= (others => '0');
--
--probe7(0)           <= pcomp_out;
--probe7(1)           <= pcomp_act;
--probe7(2)           <= enable;
--probe7(3)           <= DIR(0);
--probe7(4)           <= RELATIVE(0);
--probe7(5)           <= USE_TABLE(0);
--probe7(7 downto 6)  <= "00";
--
--END GENERATE;

end rtl;

