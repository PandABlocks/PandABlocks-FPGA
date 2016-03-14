library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity outenc_block is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Encoder I/O Pads
    a_o                 : out std_logic;
    b_o                 : out std_logic;
    z_o                 : out std_logic;
    conn_o              : out std_logic;
    sclk_i              : in  std_logic;
    sdat_i              : in  std_logic;
    sdat_o              : out std_logic;
    sdat_dir_o          : out std_logic;
    -- Block Outputs.
    slow_tlp_o          : out slow_packet;
    -- Position Field interface
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    -- Status interface
    enc_mode_o          : out encmode_t;
    iobuf_ctrl_o        : out std_logic_vector(2 downto 0)
);
end entity;

architecture rtl of outenc_block is

-- Block Configuration Registers
signal A_VAL            : std_logic_vector(31 downto 0);
signal B_VAL            : std_logic_vector(31 downto 0);
signal Z_VAL            : std_logic_vector(31 downto 0);
signal CONN_VAL         : std_logic_vector(31 downto 0);
signal ENABLE_VAL       : std_logic_vector(31 downto 0);
signal POSN_VAL         : std_logic_vector(31 downto 0);
signal PROTOCOL         : std_logic_vector(31 downto 0);
signal BITS             : std_logic_vector(31 downto 0);
signal QPERIOD          : std_logic_vector(31 downto 0);
signal QSTATE           : std_logic_vector(31 downto 0);

signal a, b, z          : std_logic;
signal conn             : std_logic;
signal posn             : std_logic_vector(31 downto 0);
signal enable           : std_logic;

signal slow             : slow_packet;

signal mem_addr         : natural range 0 to (2**mem_addr_i'length - 1);

begin

-- Integer conversion for address.
mem_addr <= to_integer(unsigned(mem_addr_i));

--
-- Control System Interface
--
outenc_ctrl : entity work.outenc_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,
    a_o                 => a,
    b_o                 => b,
    z_o                 => z,
    conn_o              => conn,
    enable_o            => enable,
    val_o               => posn,

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => open,

    -- Block Parameters
    PROTOCOL            => PROTOCOL,
    PROTOCOL_WSTB       => open,
    BITS                => BITS,
    BITS_WSTB           => open,
    QPERIOD             => QPERIOD,
    QPERIOD_WSTB        => open,
    QSTATE              => QSTATE
);

--
-- Core instantiation
--
outenc_inst : entity work.outenc
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    --
    a_i                 => a,
    b_i                 => b,
    z_i                 => z,
    conn_i              => conn,
    posn_i              => posn,
    enable_i            => enable,
    -- Encoder I/O Pads
    a_o                 => a_o,
    b_o                 => b_o,
    z_o                 => z_o,
    conn_o              => conn_o,
    sclk_i              => sclk_i,
    sdat_i              => sdat_i,
    sdat_o              => sdat_o,
    sdat_dir_o          => sdat_dir_o,
    -- Block Parameters
    PROTOCOL            => PROTOCOL(2 downto 0),
    BITS                => BITS(7 downto 0),
    QPERIOD             => QPERIOD,
    QSTATE              => QSTATE,
    -- CS Interface
    enc_mode_o          => enc_mode_o,
    iobuf_ctrl_o        => iobuf_ctrl_o
);

--
-- Issue a Write command to Slow Controller
--
SLOW_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            slow.strobe <= '0';
            slow.address <= (others => '0');
            slow.data <= (others => '0');
        else
            -- Single clock cycle strobe
            slow.strobe <= '0';
            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                if (mem_addr = OUTENC_PROTOCOL) then
                    slow.strobe <= '1';
                    slow.address <= ZEROS(PAGE_AW-BLK_AW) & mem_addr_i;
                    case (mem_dat_i(2 downto 0)) is
                        when "000"  => -- INC
                            slow.data <= ZEROS(24) & X"07";
                        when "001"  => -- SSI
                            slow.data <= ZEROS(24) & X"28";
                        when "010"  => -- EnDat
                            slow.data <= ZEROS(24) & X"10";
                        when "011"  => -- BiSS
                            slow.data <= ZEROS(24) & X"18";
                        when "100"  => -- Pass
                            slow.data <= ZEROS(24) & X"07";
                        when others =>
                            slow.strobe <= '0';
                            slow.address <= (others => '0');
                            slow.data <= (others => '0');
                    end case;
                end if;
           end if;
        end if;
    end if;
end process;

slow_tlp_o <= slow;

end rtl;

