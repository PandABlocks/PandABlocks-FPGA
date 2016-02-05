library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_outenc_block is
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

architecture rtl of panda_outenc_block is

-- Block Configuration Registers
signal A_VAL            : std_logic_vector(SBUSBW-1 downto 0);
signal B_VAL            : std_logic_vector(SBUSBW-1 downto 0);
signal Z_VAL            : std_logic_vector(SBUSBW-1 downto 0);
signal CONN_VAL         : std_logic_vector(SBUSBW-1 downto 0);
signal POSN_VAL         : std_logic_vector(PBUSBW-1 downto 0);
signal PROTOCOL         : std_logic_vector(2 downto 0);
signal BITS             : std_logic_vector(7 downto 0);
signal QPRESCALAR       : std_logic_vector(15 downto 0);
signal FORCE_QSTATE     : std_logic;
signal FORCE_QSTATE_WSTB: std_logic;
signal QSTATE           : std_logic;

signal a, b, z          : std_logic;
signal conn             : std_logic;
signal posn             : std_logic_vector(31 downto 0);

signal slow             : slow_packet;

signal mem_addr         : natural range 0 to (2**mem_addr_i'length - 1);

begin

-- Integer conversion for address.
mem_addr <= to_integer(unsigned(mem_addr_i));

--
-- Configuration Register Write/Read
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            A_VAL <= (others => '0');
            B_VAL <= (others => '0');
            Z_VAL <= (others => '0');
            CONN_VAL <= (others => '0');
            POSN_VAL <= (others => '0');
            PROTOCOL <= "000";
            BITS <= TO_SVECTOR(24, 8);
            FORCE_QSTATE <= '0';
            FORCE_QSTATE_WSTB <= '0';
            QPRESCALAR <= TO_SVECTOR(100,16);
        else
            FORCE_QSTATE_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- A Channel Select
                if (mem_addr = OUTENC_A) then
                    A_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- B Channel Select
                if (mem_addr = OUTENC_B) then
                    B_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Z Channel Select
                if (mem_addr = OUTENC_Z) then
                    Z_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Conn Channel Select
                if (mem_addr = OUTENC_CONN) then
                    CONN_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Position Bus selection
                if (mem_addr = OUTENC_POSN) then
                    POSN_VAL <= mem_dat_i(PBUSBW-1 downto 0);
                end if;

                -- Encoder Protocol
                if (mem_addr = OUTENC_PROTOCOL) then
                    PROTOCOL <= mem_dat_i(2 downto 0);
                end if;

                -- SSI Number of Bits
                if (mem_addr = OUTENC_BITS) then
                    BITS <= mem_dat_i(7 downto 0);
                end if;

                -- Quadrature Encoder Transition Period
                if (mem_addr = OUTENC_QPRESCALAR) then
                    QPRESCALAR <= mem_dat_i(15 downto 0);
                end if;

                -- Force Quadrature Encoder State
                if (mem_addr = OUTENC_FORCE_QSTATE) then
                    FORCE_QSTATE <= mem_dat_i(0);
                    FORCE_QSTATE_WSTB <= '1';
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
            mem_dat_o <= (0 => QSTATE, others => '0');
        end if;
    end if;
end process;

--
-- Design Bus Assignments
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        posn <= PFIELD(posbus_i, POSN_VAL);
    end if;
end process;

--
-- Core instantiation
--
panda_outenc_inst : entity work.panda_outenc
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
    PROTOCOL            => PROTOCOL,
    BITS                => BITS,
    QPRESCALAR          => QPRESCALAR,
    FORCE_QSTATE        => FORCE_QSTATE,
    FORCE_QSTATE_WSTB   => FORCE_QSTATE_WSTB,
    QSTATE              => QSTATE,
    -- CS Interface
    enc_mode_o          => enc_mode_o,
    iobuf_ctrl_o        => iobuf_ctrl_o
);

--
-- Pass A/B/Z through from System Bus.
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        a <= SBIT(sysbus_i, A_VAL);
        b <= SBIT(sysbus_i, B_VAL);
        z <= SBIT(sysbus_i, Z_VAL);
        conn <= SBIT(sysbus_i, CONN_VAL);
    end if;
end process;

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

