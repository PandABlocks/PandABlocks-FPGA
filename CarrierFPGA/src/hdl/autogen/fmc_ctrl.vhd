--------------------------------------------------------------------------------
--  File:       fmc_ctrl.vhd
--  Desc:       Autogenerated block control module.
--
--  Author:     Isa Uzun - Diamond Light Source
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.addr_defines.all;
use work.top_defines.all;

entity fmc_ctrl is
port (
    -- Clock and Reset
    clk_i               : in std_logic;
    reset_i             : in std_logic;
    sysbus_i            : in sysbus_t;
    posbus_i            : in posbus_t;
    -- Block Parameters
    PRESENT       : in  std_logic_vector(31 downto 0);
    OUT_PWR_ON       : out std_logic_vector(31 downto 0);
    OUT_PWR_ON_WSTB  : out std_logic;
    IN_VTSEL       : out std_logic_vector(31 downto 0);
    IN_VTSEL_WSTB  : out std_logic;
    IN_DB       : out std_logic_vector(31 downto 0);
    IN_DB_WSTB  : out std_logic;
    IN_FAULT       : in  std_logic_vector(31 downto 0);
    OUT_PUSHPL       : out std_logic_vector(31 downto 0);
    OUT_PUSHPL_WSTB  : out std_logic;
    OUT_FLTR       : out std_logic_vector(31 downto 0);
    OUT_FLTR_WSTB  : out std_logic;
    OUT_SRIAL       : out std_logic_vector(31 downto 0);
    OUT_SRIAL_WSTB  : out std_logic;
    OUT_FAULT       : in  std_logic_vector(31 downto 0);
    OUT_EN       : out std_logic_vector(31 downto 0);
    OUT_EN_WSTB  : out std_logic;
    OUT_CONFIG       : out std_logic_vector(31 downto 0);
    OUT_CONFIG_WSTB  : out std_logic;
    OUT_STATUS       : in  std_logic_vector(31 downto 0);
    out1_o : out std_logic;
    out2_o : out std_logic;
    out3_o : out std_logic;
    out4_o : out std_logic;
    out5_o : out std_logic;
    out6_o : out std_logic;
    out7_o : out std_logic;
    out8_o : out std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(BLK_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(BLK_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic
);
end fmc_ctrl;

architecture rtl of fmc_ctrl is

signal read_addr        : natural range 0 to (2**read_address_i'length - 1);
signal write_addr       : natural range 0 to (2**write_address_i'length - 1);

signal OUT1      : std_logic_vector(31 downto 0);
signal OUT1_WSTB : std_logic;
signal OUT1_DLY      : std_logic_vector(31 downto 0);
signal OUT1_DLY_WSTB : std_logic;
signal OUT2      : std_logic_vector(31 downto 0);
signal OUT2_WSTB : std_logic;
signal OUT2_DLY      : std_logic_vector(31 downto 0);
signal OUT2_DLY_WSTB : std_logic;
signal OUT3      : std_logic_vector(31 downto 0);
signal OUT3_WSTB : std_logic;
signal OUT3_DLY      : std_logic_vector(31 downto 0);
signal OUT3_DLY_WSTB : std_logic;
signal OUT4      : std_logic_vector(31 downto 0);
signal OUT4_WSTB : std_logic;
signal OUT4_DLY      : std_logic_vector(31 downto 0);
signal OUT4_DLY_WSTB : std_logic;
signal OUT5      : std_logic_vector(31 downto 0);
signal OUT5_WSTB : std_logic;
signal OUT5_DLY      : std_logic_vector(31 downto 0);
signal OUT5_DLY_WSTB : std_logic;
signal OUT6      : std_logic_vector(31 downto 0);
signal OUT6_WSTB : std_logic;
signal OUT6_DLY      : std_logic_vector(31 downto 0);
signal OUT6_DLY_WSTB : std_logic;
signal OUT7      : std_logic_vector(31 downto 0);
signal OUT7_WSTB : std_logic;
signal OUT7_DLY      : std_logic_vector(31 downto 0);
signal OUT7_DLY_WSTB : std_logic;
signal OUT8      : std_logic_vector(31 downto 0);
signal OUT8_WSTB : std_logic;
signal OUT8_DLY      : std_logic_vector(31 downto 0);
signal OUT8_DLY_WSTB : std_logic;

begin

-- Unused outputs
read_ack_o <= '0';
write_ack_o <= '0';

read_addr <= to_integer(unsigned(read_address_i));
write_addr <= to_integer(unsigned(write_address_i));

--
-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            OUT1 <= (others => '0');
            OUT1_WSTB <= '0';
            OUT1_DLY <= (others => '0');
            OUT1_DLY_WSTB <= '0';
            OUT2 <= (others => '0');
            OUT2_WSTB <= '0';
            OUT2_DLY <= (others => '0');
            OUT2_DLY_WSTB <= '0';
            OUT3 <= (others => '0');
            OUT3_WSTB <= '0';
            OUT3_DLY <= (others => '0');
            OUT3_DLY_WSTB <= '0';
            OUT4 <= (others => '0');
            OUT4_WSTB <= '0';
            OUT4_DLY <= (others => '0');
            OUT4_DLY_WSTB <= '0';
            OUT5 <= (others => '0');
            OUT5_WSTB <= '0';
            OUT5_DLY <= (others => '0');
            OUT5_DLY_WSTB <= '0';
            OUT6 <= (others => '0');
            OUT6_WSTB <= '0';
            OUT6_DLY <= (others => '0');
            OUT6_DLY_WSTB <= '0';
            OUT7 <= (others => '0');
            OUT7_WSTB <= '0';
            OUT7_DLY <= (others => '0');
            OUT7_DLY_WSTB <= '0';
            OUT8 <= (others => '0');
            OUT8_WSTB <= '0';
            OUT8_DLY <= (others => '0');
            OUT8_DLY_WSTB <= '0';
            OUT_PWR_ON <= (others => '0');
            OUT_PWR_ON_WSTB <= '0';
            IN_VTSEL <= (others => '0');
            IN_VTSEL_WSTB <= '0';
            IN_DB <= (others => '0');
            IN_DB_WSTB <= '0';
            OUT_PUSHPL <= (others => '0');
            OUT_PUSHPL_WSTB <= '0';
            OUT_FLTR <= (others => '0');
            OUT_FLTR_WSTB <= '0';
            OUT_SRIAL <= (others => '0');
            OUT_SRIAL_WSTB <= '0';
            OUT_EN <= (others => '0');
            OUT_EN_WSTB <= '0';
            OUT_CONFIG <= (others => '0');
            OUT_CONFIG_WSTB <= '0';
        else
            OUT1_WSTB <= '0';
            OUT1_DLY_WSTB <= '0';
            OUT2_WSTB <= '0';
            OUT2_DLY_WSTB <= '0';
            OUT3_WSTB <= '0';
            OUT3_DLY_WSTB <= '0';
            OUT4_WSTB <= '0';
            OUT4_DLY_WSTB <= '0';
            OUT5_WSTB <= '0';
            OUT5_DLY_WSTB <= '0';
            OUT6_WSTB <= '0';
            OUT6_DLY_WSTB <= '0';
            OUT7_WSTB <= '0';
            OUT7_DLY_WSTB <= '0';
            OUT8_WSTB <= '0';
            OUT8_DLY_WSTB <= '0';
            OUT_PWR_ON_WSTB <= '0';
            IN_VTSEL_WSTB <= '0';
            IN_DB_WSTB <= '0';
            OUT_PUSHPL_WSTB <= '0';
            OUT_FLTR_WSTB <= '0';
            OUT_SRIAL_WSTB <= '0';
            OUT_EN_WSTB <= '0';
            OUT_CONFIG_WSTB <= '0';

            if (write_strobe_i = '1') then
                -- Input Select Control Registers
                if (write_addr = FMC_OUT1) then
                    OUT1 <= write_data_i;
                    OUT1_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT1_DLY) then
                    OUT1_DLY <= write_data_i;
                    OUT1_DLY_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT2) then
                    OUT2 <= write_data_i;
                    OUT2_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT2_DLY) then
                    OUT2_DLY <= write_data_i;
                    OUT2_DLY_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT3) then
                    OUT3 <= write_data_i;
                    OUT3_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT3_DLY) then
                    OUT3_DLY <= write_data_i;
                    OUT3_DLY_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT4) then
                    OUT4 <= write_data_i;
                    OUT4_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT4_DLY) then
                    OUT4_DLY <= write_data_i;
                    OUT4_DLY_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT5) then
                    OUT5 <= write_data_i;
                    OUT5_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT5_DLY) then
                    OUT5_DLY <= write_data_i;
                    OUT5_DLY_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT6) then
                    OUT6 <= write_data_i;
                    OUT6_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT6_DLY) then
                    OUT6_DLY <= write_data_i;
                    OUT6_DLY_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT7) then
                    OUT7 <= write_data_i;
                    OUT7_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT7_DLY) then
                    OUT7_DLY <= write_data_i;
                    OUT7_DLY_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT8) then
                    OUT8 <= write_data_i;
                    OUT8_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT8_DLY) then
                    OUT8_DLY <= write_data_i;
                    OUT8_DLY_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT_PWR_ON) then
                    OUT_PWR_ON <= write_data_i;
                    OUT_PWR_ON_WSTB <= '1';
                end if;
                if (write_addr = FMC_IN_VTSEL) then
                    IN_VTSEL <= write_data_i;
                    IN_VTSEL_WSTB <= '1';
                end if;
                if (write_addr = FMC_IN_DB) then
                    IN_DB <= write_data_i;
                    IN_DB_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT_PUSHPL) then
                    OUT_PUSHPL <= write_data_i;
                    OUT_PUSHPL_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT_FLTR) then
                    OUT_FLTR <= write_data_i;
                    OUT_FLTR_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT_SRIAL) then
                    OUT_SRIAL <= write_data_i;
                    OUT_SRIAL_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT_EN) then
                    OUT_EN <= write_data_i;
                    OUT_EN_WSTB <= '1';
                end if;
                if (write_addr = FMC_OUT_CONFIG) then
                    OUT_CONFIG <= write_data_i;
                    OUT_CONFIG_WSTB <= '1';
                end if;

            end if;
        end if;
    end if;
end process;

--
-- Status Register Read
--
REG_READ : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            read_data_o <= (others => '0');
        else
            case (read_addr) is
                when FMC_PRESENT =>
                    read_data_o <= PRESENT;
                when FMC_IN_FAULT =>
                    read_data_o <= IN_FAULT;
                when FMC_OUT_FAULT =>
                    read_data_o <= OUT_FAULT;
                when FMC_OUT_STATUS =>
                    read_data_o <= OUT_STATUS;
                when others =>
                    read_data_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

--
-- Instantiate Delay Blocks for System and Position Bus Fields
--
bitmux_OUT1 : entity work.bitmux
port map (
    clk_i       => clk_i,
    sysbus_i    => sysbus_i,
    bit_o       => out1_o,
    BITMUX_SEL  => OUT1,
    BIT_DLY     => OUT1_DLY
);

bitmux_OUT2 : entity work.bitmux
port map (
    clk_i       => clk_i,
    sysbus_i    => sysbus_i,
    bit_o       => out2_o,
    BITMUX_SEL  => OUT2,
    BIT_DLY     => OUT2_DLY
);

bitmux_OUT3 : entity work.bitmux
port map (
    clk_i       => clk_i,
    sysbus_i    => sysbus_i,
    bit_o       => out3_o,
    BITMUX_SEL  => OUT3,
    BIT_DLY     => OUT3_DLY
);

bitmux_OUT4 : entity work.bitmux
port map (
    clk_i       => clk_i,
    sysbus_i    => sysbus_i,
    bit_o       => out4_o,
    BITMUX_SEL  => OUT4,
    BIT_DLY     => OUT4_DLY
);

bitmux_OUT5 : entity work.bitmux
port map (
    clk_i       => clk_i,
    sysbus_i    => sysbus_i,
    bit_o       => out5_o,
    BITMUX_SEL  => OUT5,
    BIT_DLY     => OUT5_DLY
);

bitmux_OUT6 : entity work.bitmux
port map (
    clk_i       => clk_i,
    sysbus_i    => sysbus_i,
    bit_o       => out6_o,
    BITMUX_SEL  => OUT6,
    BIT_DLY     => OUT6_DLY
);

bitmux_OUT7 : entity work.bitmux
port map (
    clk_i       => clk_i,
    sysbus_i    => sysbus_i,
    bit_o       => out7_o,
    BITMUX_SEL  => OUT7,
    BIT_DLY     => OUT7_DLY
);

bitmux_OUT8 : entity work.bitmux
port map (
    clk_i       => clk_i,
    sysbus_i    => sysbus_i,
    bit_o       => out8_o,
    BITMUX_SEL  => OUT8,
    BIT_DLY     => OUT8_DLY
);




end rtl;