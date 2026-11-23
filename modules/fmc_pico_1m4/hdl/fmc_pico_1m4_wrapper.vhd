-- Interface to CAENels FMC-Pico-1M4 Four Channel ADC

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.support.all;
use work.top_defines.all;
use work.interface_types.all;

entity fmc_pico_1m4_wrapper is
    generic (
        CLOCK_DIVISOR : natural := 5;
        DATA_BITS : natural := 20
    );
    port (
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        
        -- Outputs to BitBus from FMC
        val1_o               : out std32_array(0 downto 0);
        val2_o               : out std32_array(0 downto 0);
        val3_o               : out std32_array(0 downto 0);
        val4_o               : out std32_array(0 downto 0);

        -- FMC
        FMC                 : view FMC_Module;

        -- Bus Inputs
        bit_bus_i           : in  bit_bus_t;
        pos_bus_i           : in  pos_bus_t;

        -- Memory Bus Interface
        read_strobe_i       : in  std_logic;
        read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
        read_data_o         : out std_logic_vector(31 downto 0);
        read_ack_o          : out std_logic;

        write_strobe_i      : in  std_logic;
        write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
        write_data_i        : in  std_logic_vector(31 downto 0);
        write_ack_o         : out std_logic
    );
end;

architecture arch of fmc_pico_1m4_wrapper is

    COMPONENT ila_0
    
    PORT (
        clk : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe4 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        probe5 : IN STD_LOGIC_VECTOR(19 DOWNTO 0)
    );
    END COMPONENT  ;
    
    signal cnv              : std_ulogic;
    signal sck              : std_ulogic;
    signal sck_rtrn         : std_ulogic;
    signal sdo           : std_ulogic_vector(0 to 3);
    signal busy_cmn         : std_ulogic;
    signal fmc_in           : std32_array(7 downto 0);
    signal busy           : std_ulogic;
        -- Data returned
    signal valid          : std_ulogic;       -- Strobed on data ready out
    signal data           : signed_array(0 to 3)(DATA_BITS-1 downto 0);
    signal start          : std_ulogic;
            -- Range selection
    signal range_i        : std_ulogic_vector(0 to 3);
    signal capture_edge    : std_ulogic;
    signal capture_counterr : unsigned(4 downto 0);

begin


    io : entity work.fmc_pico_1m4_io port map (
        FMC         => FMC,

        cnv_i       => cnv,
        sck_i       => sck,
        sck_rtrn_o  => sck_rtrn,
        sdo_o       => sdo,
        busy_cmn_o  => busy_cmn,

        r_i         => range_i,

        -- The LEDs are futile as they're not on the front panel
        led_i       => "00",

        -- I2C interface currently unused
        a_scl_i     => '1',
        a_scl_o     => open,
        a_sda_i     => '1',
        a_sda_o     => open
    );



    capture : entity work.fmc_pico_1m4_capture generic map (
        CLOCK_DIVISOR => CLOCK_DIVISOR,
        DATA_BITS     => DATA_BITS
    ) port map (
        clk_i         => clk_i,

        cnv_o         => cnv,
        sck_o         => sck,
        sck_rtrn_i    => sck_rtrn,
        sdo_i         => sdo,
        busy_cmn_i    => busy_cmn,

        start_i       => start,
        busy_o        => busy,
        valid_o       => valid,
        data_o        => data,
        capture_edge  => capture_edge,
        capture_counterr => capture_counterr
    );

    fmc_pico_1m4_inst : entity work.fmc_pico_1m4_ctrl
    port map(
        clk_i               => clk_i,
        reset_i             => reset_i,
        bit_bus_i           => bit_bus_i,
        pos_bus_i           => pos_bus_i,
        START_from_bus      => start,
        RANGE0_from_bus     => range_i(0),
        RANGE1_from_bus     => range_i(1),
        RANGE2_from_bus     => range_i(2),
        RANGE3_from_bus     => range_i(3),
        -- Memory Bus Interface
        read_strobe_i       => read_strobe_i,
        read_address_i      => read_address_i(BLK_AW-1 downto 0),
        read_data_o         => read_data_o,
        read_ack_o          => read_ack_o,

        write_strobe_i      => write_strobe_i,
        write_address_i     => write_address_i(BLK_AW-1 downto 0),
        write_data_i        => write_data_i,
        write_ack_o         => write_ack_o
    );
    
    debug : ila_0
    PORT MAP (
        clk => clk_i,
        probe0(0) => start, 
        probe1(0) => valid, 
        probe2(0) => busy, 
        probe3(0) => capture_edge,
        probe4 => std_logic_vector(capture_counterr),
        probe5 => std_logic_vector(data(0))
    );

---------------------------------------------------------------------------
-- Assign outputs
---------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        if valid then
            val1_o(0) <= std_logic_vector(resize(data(0), 32));
            val2_o(0) <= std_logic_vector(resize(data(1), 32));
            val3_o(0) <= std_logic_vector(resize(data(2), 32));
            val4_o(0) <= std_logic_vector(resize(data(3), 32));
        end if;
    end if;
end process;

end;
