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

signal quad_a           : std_logic;
signal quad_b           : std_logic;

signal a_pass           : std_logic;
signal b_pass           : std_logic;
signal z_pass           : std_logic;
signal conn_pass        : std_logic;

signal sdat_dir         : std_logic := '0';
signal posn             : std_logic_vector(31 downto 0);

begin

-- Status information to upper-level
enc_mode_o <= PROTOCOL;
sdat_dir_o <= sdat_dir;

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
                if (mem_addr_i = OUTENC_A_VAL_ADDR) then
                    A_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- B Channel Select
                if (mem_addr_i = OUTENC_B_VAL_ADDR) then
                    B_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Z Channel Select
                if (mem_addr_i = OUTENC_Z_VAL_ADDR) then
                    Z_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Conn Channel Select
                if (mem_addr_i = OUTENC_CONN_VAL_ADDR) then
                    CONN_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Position Bus selection
                if (mem_addr_i = OUTENC_POSN_VAL_ADDR) then
                    POSN_VAL <= mem_dat_i(PBUSBW-1 downto 0);
                end if;

                -- Encoder Protocol
                if (mem_addr_i = OUTENC_PROTOCOL_ADDR) then
                    PROTOCOL <= mem_dat_i(2 downto 0);
                end if;

                -- SSI Number of Bits
                if (mem_addr_i = OUTENC_BITS_ADDR) then
                    BITS <= mem_dat_i(7 downto 0);
                end if;

                -- Quadrature Encoder Transition Period
                if (mem_addr_i = OUTENC_QPRESCALAR_ADDR) then
                    QPRESCALAR <= mem_dat_i(15 downto 0);
                end if;

                -- Force Quadrature Encoder State
                if (mem_addr_i = OUTENC_FRC_QSTATE_ADDR) then
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
            case (mem_addr_i) is
                when OUTENC_QSTATE_ADDR =>
                    mem_dat_o <= (0 => qstate, others => '0');
                when others =>
            end case;
        end if;
    end if;
end process;

--
-- Setup IOBUF Control Values :
--  Due to Encoder I/O multiplexing on device pins, on-chip
--  IOBUFs have to be configured according to protocol selected.
IOBUF_CTRL : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            iobuf_ctrl_o <= "000";
        else
            case (PROTOCOL) is
                when "000"  =>                        -- INC
                    iobuf_ctrl_o <= "000";
                when "001"  =>                        -- SSI
                    iobuf_ctrl_o <= "011";
                when "010"  =>                        -- EnDat
                    iobuf_ctrl_o <= sdat_dir & "10";
                when "011"  =>                        -- BiSS
                    iobuf_ctrl_o <= sdat_dir & "10";
                when "100"  =>                        -- Pass-Through
                    iobuf_ctrl_o <= "000";
                when others =>
                    iobuf_ctrl_o <= "000";
            end case;
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
-- INCREMENTAL OUT
--
panda_quadout_inst : entity work.panda_quadout
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    qenc_presc_i    => QPRESCALAR,
    force_val_i     => FORCE_QSTATE,
    force_wstb_i    => FORCE_QSTATE_WSTB,
    posn_i          => posn,
    qstate_o        => qstate,
    a_o             => quad_a,
    b_o             => quad_b
);

--
-- Pass A/B/Z through from System Bus.
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        a_pass <= SBIT(sysbus_i, A_VAL);
        b_pass <= SBIT(sysbus_i, B_VAL);
        z_pass <= SBIT(sysbus_i, Z_VAL);
        conn_pass <= SBIT(sysbus_i, CONN_VAL);
    end if;
end process;

a_o <= a_pass when (PROTOCOL = "100") else quad_a;
b_o <= b_pass when (PROTOCOL = "100") else quad_b;
z_o <= z_pass when (PROTOCOL = "100") else '0';

conn_o <= conn_pass;

--
-- SSI SLAVE
--
panda_ssislv_inst : entity work.panda_ssislv
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    enc_bits_i      => BITS,
    ssi_sck_i       => sclk_i,
    ssi_dat_o       => sdat_o,
    posn_i          => posn,
    ssi_rd_sof      => open
);

end rtl;

