library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;

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
    posn_i              : in  posn_t;
    -- Status interface
    conn_i              : in  std_logic;
    enc_mode_o          : out encmode_t;

    iobuf_ctrl_o        : out std_logic_vector(2 downto 0)
);
end entity;

architecture rtl of panda_encout is

-- Block Configuration Registers
signal ENCOUT_PROT          : std_logic_vector(2 downto 0);
signal ENCOUT_BITS          : std_logic_vector(7 downto 0);
signal ENCOUT_FRC_QSTATE    : std_logic;
signal ENCOUT_QSTATE        : std_logic;
signal ENCOUT_QPRESCALAR    : std_logic_vector(15 downto 0);

-- Signals
signal reset                : std_logic;
signal sdat_dir             : std_logic := '0';

begin

enc_mode_o <= ENCOUT_PROT;
sdat_dir_o <= sdat_dir;

--
-- Configuration Register Write/Read
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ENCOUT_PROT     <= "000";
            ENCOUT_BITS     <= TO_STD_VECTOR(24, 8);
            ENCOUT_FRC_QSTATE <= '0';
            ENCOUT_QPRESCALAR <= TO_STD_VECTOR(100,16);
        else
            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                if (mem_addr_i = ENCOUT_PROT_ADDR) then
                    ENCOUT_PROT <= mem_dat_i(2 downto 0);
                end if;

                if (mem_addr_i = ENCOUT_BITS_ADDR) then
                    ENCOUT_BITS <= mem_dat_i(7 downto 0);
                end if;

                if (mem_addr_i = ENCOUT_FRC_QSTATE_ADDR) then
                    ENCOUT_FRC_QSTATE <= mem_dat_i(0);
                end if;

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
                    mem_dat_o <= (0 => '1', others => '0');
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
-- INCREMENTAL OUT
--
a_o <= '0';
b_o <= '0';
z_o <= '0';

--
-- SSI SLAVE
--
reset <= not ENCOUT_PROT(0);

panda_ssislv_inst : entity work.panda_ssislv
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    enc_bits_i      => ENCOUT_BITS,
    ssi_sck_i       => sclk_i,
    ssi_dat_o       => sdat_o,
    posn_i          => posn_i,
    ssi_rd_sof      => open
);



end rtl;

