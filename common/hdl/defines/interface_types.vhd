library ieee;
use ieee.std_logic_1164.all;

package interface_types is

    -- FMC Block Record declarations

    type FMC_interface is
      record
        FMC_PRSNT       : std_logic_vector(1 downto 0);
        FMC_LA_P        : std_logic_vector(33 downto 0);
        FMC_LA_N        : std_logic_vector(33 downto 0);
        FMC_CLK0_M2C_P  : std_logic;
        FMC_CLK0_M2C_N  : std_logic;
        FMC_CLK1_M2C_P  : std_logic;
        FMC_CLK1_M2C_N  : std_logic;
        FMC_I2C_SDA_in  : std_logic;
        FMC_I2C_SDA_out : std_logic;
        FMC_I2C_SDA_tri : std_logic;
        FMC_I2C_SCL_in  : std_logic;
        FMC_I2C_SCL_out : std_logic;
        FMC_I2C_SCL_tri : std_logic;
      end record FMC_interface;

    view FMC_Module of FMC_interface is
        FMC_PRSNT       : in;
        FMC_LA_P        : inout;
        FMC_LA_N        : inout;
        FMC_CLK0_M2C_P  : inout;
        FMC_CLK0_M2C_N  : inout;
        FMC_CLK1_M2C_P  : in;
        FMC_CLK1_M2C_N  : in;
        FMC_I2C_SDA_in  : out;
        FMC_I2C_SDA_out : in;
        FMC_I2C_SDA_tri : in;
        FMC_I2C_SCL_in  : out;
        FMC_I2C_SCL_out : in;
        FMC_I2C_SCL_tri : in;

    end view FMC_Module;

    constant FMC_init : FMC_interface;

    type FMC_array is array (natural range <>) of FMC_interface;

    type FMC_ARR_REC is record
        FMC_ARR : FMC_array;
    end record FMC_ARR_REC;

    view FMC_MOD_ARR of FMC_ARR_REC is
        FMC_ARR: view (FMC_Module);
    end view;

    -- SFP Block Record declarations

    type MGT_interface is
      record
        SFP_LOS     : std_logic;
        GTREFCLK    : std_logic;
        RXN_IN      : std_logic;
        RXP_IN      : std_logic;
        TXN_OUT     : std_logic;
        TXP_OUT     : std_logic;
        MGT_REC_CLK : std_logic;
        LINK_UP     : std_logic;
        TS_SEC      : std_logic_vector(31 downto 0);
        TS_TICKS    : std_logic_vector(31 downto 0);
        MAC_ADDR    : std_logic_vector(47 downto 0);
        MAC_ADDR_WS : std_logic;
      end record MGT_interface;

    view MGT_Module of MGT_interface is
        SFP_LOS     : in;
        GTREFCLK    : in;
        RXN_IN      : in;
        RXP_IN      : in;
        TXN_OUT     : out;
        TXP_OUT     : out;
        MGT_REC_CLK : out;
        LINK_UP     : out;
        TS_SEC      : out;
        TS_TICKS    : out;
        MAC_ADDR    : in;
        MAC_ADDR_WS : in;
    end view MGT_Module;

    constant MGT_init : MGT_interface;

    type MGT_array is array (natural range <>) of MGT_interface;

    type MGT_ARR_REC is record
        MGT_ARR : MGT_array;
    end record MGT_ARR_REC;

    view MGT_MOD_ARR of MGT_ARR_REC is
        MGT_ARR: view (MGT_Module);
    end view;
end;

package body interface_types is

    constant FMC_init : FMC_interface := (  FMC_PRSNT => "00",
                                            FMC_LA_P => (others => 'Z'),
                                            FMC_LA_N => (others => 'Z'),
                                            FMC_CLK0_M2C_P => 'Z',
                                            FMC_CLK0_M2C_N => 'Z',
                                            FMC_CLK1_M2C_P => '0',
                                            FMC_CLK1_M2C_N => '0',
                                            FMC_I2C_SDA_in => '0',
                                            FMC_I2C_SDA_out => '0',
                                            FMC_I2C_SDA_tri => '1',
                                            FMC_I2C_SCL_in => '0',
                                            FMC_I2C_SCL_out => '0',
                                            FMC_I2C_SCL_tri => '1');

    constant MGT_init : MGT_interface := (  SFP_LOS => '0',
                                            GTREFCLK => '0',
                                            RXN_IN => '0',
                                            RXP_IN => '0',
                                            TXN_OUT => 'Z',
                                            TXP_OUT => 'Z',
                                            MGT_REC_CLK => '0',
                                            LINK_UP => '0',
                                            TS_SEC => (others => '0'),
                                            TS_TICKS => (others => '0'),
                                            MAC_ADDR => (others => '0'),
                                            MAC_ADDR_WS => '0');

end;
