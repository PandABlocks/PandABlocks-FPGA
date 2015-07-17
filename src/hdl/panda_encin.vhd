library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;

entity panda_encin is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    -- Encoder I/O Pads
    a_i                 : in  std_logic;
    b_i                 : in  std_logic;
    z_i                 : in  std_logic;
    mclk_o              : out std_logic;
    mdat_i              : in  std_logic;
    mdat_o              : out std_logic;
    -- Status
    posn_o              : out std_logic_vector(31 downto 0);
    posn_valid_o        : out std_logic;
    iobuf_ctrl_o        : out std_logic_vector(2 downto 0)
);
end entity;

architecture rtl of panda_encin is

-- Block Configuration Registers
signal ENCIN_PROT       : std_logic_vector(2 downto 0);
signal ENCIN_PRESC      : std_logic_vector(15 downto 0);
signal ENCIN_RATE       : std_logic_vector(15 downto 0);
signal ENCIN_BITS       : std_logic_vector(7 downto 0);
signal ENCIN_SETP       : std_logic_vector(31 downto 0);

-- Signals
signal reset            : std_logic;
signal endat_mdir       : std_logic := '0';

begin

--
-- Configuration Register Read
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ENCIN_PROT     <= "000";
            ENCIN_PRESC    <= TO_STD_VECTOR(100,16);
            ENCIN_RATE     <= TO_STD_VECTOR(100,16);
            ENCIN_BITS     <= TO_STD_VECTOR(24, 8);
            ENCIN_SETP     <= TO_STD_VECTOR(0, 32);
        else
            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                if (mem_addr_i = ENCIN_PROT_ADDR) then
                    ENCIN_PROT <= mem_dat_i(2 downto 0);
                end if;

                if (mem_addr_i = ENCIN_RATE_ADDR) then
                    ENCIN_RATE <= mem_dat_i(15 downto 0);
                end if;

                if (mem_addr_i = ENCIN_BITS_ADDR) then
                    ENCIN_BITS <= mem_dat_i(7 downto 0);
                end if;

                if (mem_addr_i = ENCIN_SETP_ADDR) then
                    ENCIN_SETP <= mem_dat_i(31 downto 0);
                end if;

            end if;
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
            case (ENCIN_PROT) is
                when "000"  =>                              -- INC
                    iobuf_ctrl_o <= "111";
                when "001"  =>                              -- SSI
                    iobuf_ctrl_o <= "101";
                when "010"  =>                              -- EnDat
                    iobuf_ctrl_o <= endat_mdir & "00";
                when "011"  =>                              -- BiSS
                    iobuf_ctrl_o <= endat_mdir & "00";
                when others =>
                    iobuf_ctrl_o <= "111";
            end case;
        end if;
    end if;
end process;

-- SSI Master Instantiation :
--  Master continuously reads from Absolute Encoder
--  at 1MHz (50MHz/SSI_CLK_DIV).

reset <= not ENCIN_PROT(0);

panda_ssimstr_inst : entity work.panda_ssimstr
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    enc_bits_i      => ENCIN_BITS,
    enc_presc_i     => ENCIN_PRESC,
    enc_rate_i      => ENCIN_RATE,
    ssi_sck_o       => mclk_o,
    ssi_dat_i       => mdat_i,
    posn_o          => posn_o,
    posn_valid_o    => posn_valid_o
);

end rtl;

