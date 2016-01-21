library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;

entity panda_inenc is
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
    -- Block Parameters
    PROTOCOL            : in  std_logic_vector(2 downto 0);
    CLKRATE             : in  std_logic_vector(15 downto 0);
    FRAMERATE           : in  std_logic_vector(15 downto 0);
    BITS                : in  std_logic_vector(7 downto 0);
    SETP                : in  std_logic_vector(31 downto 0);
    SETP_WSTB           : in  std_logic;
    RST_ON_Z            : in  std_logic;
    -- Block Outputs
    posn_o              : out std_logic_vector(31 downto 0);
    iobuf_ctrl_o        : out std_logic_vector(2 downto 0)
);
end entity;

architecture rtl of panda_inenc is

signal endat_mdir       : std_logic := '0';
signal posn_incr        : std_logic_vector(31 downto 0);
signal posn_ssi         : std_logic_vector(31 downto 0);

begin

-- Unused signals
mdat_o <= '0';

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
            case (PROTOCOL) is
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

--
-- Incremental Encoder Instantiation :
--
panda_quadin : entity work.panda_quadin
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    a_i             => a_i,
    b_i             => b_i,
    z_i             => z_i,
    setp_val_i      => SETP,
    setp_wstb_i     => SETP_WSTB,
    rst_z_i         => RST_ON_Z,
    posn_o          => posn_incr
);

--
-- SSI Master Instantiation :
--
panda_ssimstr_inst : entity work.panda_ssimstr
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    enc_bits_i      => BITS,
    enc_presc_i     => CLKRATE,
    enc_rate_i      => FRAMERATE,
    ssi_sck_o       => mclk_o,
    ssi_dat_i       => mdat_i,
    posn_o          => posn_ssi,
    posn_valid_o    => open
);

--
-- Position Output Multiplexer
--
POSN_MUX : process(clk_i)
begin
    if rising_edge(clk_i) then
        case (PROTOCOL) is
            when "000"  =>              -- INC
                posn_o <= posn_incr;
            when "001"  =>              -- SSI
                posn_o <= posn_ssi;
            when others =>
                posn_o <= posn_incr;
        end case;
    end if;
end process;

end rtl;
