entity fmc_top is
port (
    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Standard FMC Block ports, do not add to or delete
    clk_i               : in  std_logic;
    clk_aux_i           : in  std_logic;
    reset_i             : in  std_logic;
    -- System Bus Inputs
    bit_bus_i            : in  std_logic_vector(127 downto 0);
    pos_bus_i            : in  std32_array(31 downto 0);
    -- Generic Inputs to BitBus and PosBus from FMC and SFP
    fmc_inputs_o        : out std_logic_vector(15 downto 0);
    fmc_data_o          : out std32_array(15 downto 0);
    -- PandABlocks Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- External Differential Clock (via front panel SMA)
    EXTCLK_P            : in    std_logic;
    EXTCLK_N            : in    std_logic;
    -- FMC LPC - LA I/O
    FMC_PRSNT           : in    std_logic;
    FMC_LA_P            : inout std_logic_vector(33 downto 0);
    FMC_LA_N            : inout std_logic_vector(33 downto 0);
    FMC_CLK0_M2C_P      : in    std_logic;
    FMC_CLK0_M2C_N      : in    std_logic;
    FMC_CLK1_M2C_P      : in    std_logic;
    FMC_CLK1_M2C_N      : in    std_logic;
    -- FMC LCP - GTX I/O
    TXP_OUT             : out   std_logic;
    TXN_OUT             : out   std_logic;
    RXP_IN              : in    std_logic;
    RXN_IN              : in    std_logic;
    GTREFCLK_P          : in    std_logic;
    GTREFCLK_N          : in    std_logic
);
end fmc_top;

