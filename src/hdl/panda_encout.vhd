library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_encout is
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
    sclk_i              : in  std_logic;
    sdat_i              : in  std_logic;
    sdat_o              : out std_logic;
    sdat_dir_o          : out std_logic;
    -- Position Field interface
    posbus_i            : in  posbus_t;
    -- Status interface
    enc_mode_o          : out encmode_t;
    iobuf_ctrl_o        : out std_logic_vector(2 downto 0)
);
end entity;

architecture rtl of panda_encout is

-- Block Configuration Registers
signal ENCOUT_POSN_VAL          : std_logic_vector(PBUSBW-1 downto 0);
signal ENCOUT_PROT              : std_logic_vector(2 downto 0);
signal ENCOUT_BITS              : std_logic_vector(7 downto 0);
signal ENCOUT_FRC_QSTATE        : std_logic;
signal ENCOUT_FRC_QSTATE_WSTB   : std_logic;
signal ENCOUT_QSTATE            : std_logic;
signal ENCOUT_QPRESCALAR        : std_logic_vector(15 downto 0);

signal sdat_dir                 : std_logic := '0';
signal qstate                   : std_logic;
signal posn_val                 : std_logic_vector(31 downto 0);

begin

-- Status information to upper-level
enc_mode_o <= ENCOUT_PROT;
sdat_dir_o <= sdat_dir;

--
-- Configuration Register Write/Read
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ENCOUT_POSN_VAL <= (others => '0');
            ENCOUT_PROT <= "000";
            ENCOUT_BITS <= TO_SVECTOR(24, 8);
            ENCOUT_FRC_QSTATE <= '0';
            ENCOUT_QPRESCALAR <= TO_SVECTOR(100,16);
        else
            ENCOUT_FRC_QSTATE_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Pulse start position
                if (mem_addr_i = ENCOUT_POSN_VAL_ADDR) then
                    ENCOUT_POSN_VAL <= mem_dat_i(PBUSBW-1 downto 0);
                end if;

                -- Encoder Protocol
                if (mem_addr_i = ENCOUT_PROT_ADDR) then
                    ENCOUT_PROT <= mem_dat_i(2 downto 0);
                end if;

                -- SSI Number of Bits
                if (mem_addr_i = ENCOUT_BITS_ADDR) then
                    ENCOUT_BITS <= mem_dat_i(7 downto 0);
                end if;

                -- Force Quadrature Encoder State
                if (mem_addr_i = ENCOUT_FRC_QSTATE_ADDR) then
                    ENCOUT_FRC_QSTATE <= mem_dat_i(0);
                    ENCOUT_FRC_QSTATE_WSTB <= '1';
                end if;

                -- Quadrature Encoder Transition Period
                if (mem_addr_i = ENCOUT_QPRESCALAR_ADDR) then
                    ENCOUT_QPRESCALAR <= mem_dat_i(15 downto 0);
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
                when ENCOUT_QSTATE_ADDR =>
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
            iobuf_ctrl_o <= "111";
        else
            case (ENCOUT_PROT) is
                when "000"  =>                        -- INC
                    iobuf_ctrl_o <= "000";
                when "001"  =>                        -- SSI
                    iobuf_ctrl_o <= "011";
                when "010"  =>                        -- EnDat
                    iobuf_ctrl_o <= sdat_dir & "10";
                when "011"  =>                        -- BiSS
                    iobuf_ctrl_o <= sdat_dir & "10";
                when others =>
                    iobuf_ctrl_o <= "000";
            end case;
        end if;
    end if;
end process;

--
-- Design Bus Assignments
--
posn_val <= PFIELD(posbus_i, ENCOUT_POSN_VAL);

--
-- INCREMENTAL OUT
--
panda_quadout_inst : entity work.panda_quadout
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    qenc_presc_i    => ENCOUT_QPRESCALAR,
    force_val_i     => ENCOUT_FRC_QSTATE,
    force_wstb_i    => ENCOUT_FRC_QSTATE_WSTB,
    posn_i          => posn_val,
    qstate_o        => qstate,
    a_o             => a_o,
    b_o             => b_o
);

z_o <= '0';

--
-- SSI SLAVE
--

panda_ssislv_inst : entity work.panda_ssislv
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    enc_bits_i      => ENCOUT_BITS,
    ssi_sck_i       => sclk_i,
    ssi_dat_o       => sdat_o,
    posn_i          => posn_val,
    ssi_rd_sof      => open
);

end rtl;

