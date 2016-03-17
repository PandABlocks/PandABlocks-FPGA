--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Interface to external RS485 Encoder Input Channels.
--                The blocks support various standards which is controlled by
--                PROTOCOL register input.
--
--                To save I/O pins, the design multiplexed 3-pins to implement
--                supported protocols.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;

entity inenc is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Encoder I/O Pads
    a_i                 : in  std_logic;
    b_i                 : in  std_logic;
    z_i                 : in  std_logic;
    mclk_o              : out std_logic;
    mdat_i              : in  std_logic;
    mdat_o              : out std_logic;
    conn_i              : in  std_logic;
    -- Loopback outputs
    a_o                 : out std_logic;
    b_o                 : out std_logic;
    z_o                 : out std_logic;
    conn_o              : out std_logic;
    -- Block Parameters
    PROTOCOL            : in  std_logic_vector(2 downto 0);
    CLKRATE             : in  std_logic_vector(31 downto 0);
    FRAMERATE           : in  std_logic_vector(31 downto 0);
    BITS                : in  std_logic_vector(7 downto 0);
    SETP                : in  std_logic_vector(31 downto 0);
    SETP_WSTB           : in  std_logic;
    RST_ON_Z            : in  std_logic;
    -- Block Outputs
    posn_o              : out std_logic_vector(31 downto 0);
    iobuf_ctrl_o        : out std_logic_vector(2 downto 0)
);
end entity;

architecture rtl of inenc is

signal endat_mdir       : std_logic;
signal posn_incr        : std_logic_vector(31 downto 0);
signal posn_ssi         : std_logic_vector(31 downto 0);

begin

-- Unused signals
mdat_o <= '0';
endat_mdir <= '0';

-- Output assignments
a_o <= a_i;
b_o <= b_i;
z_o <= z_i;
conn_o <= conn_i;

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
qdec : entity work.qdec
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    a_i             => a_i,
    b_i             => b_i,
    z_i             => z_i,
    SETP            => SETP,
    SETP_WSTB       => SETP_WSTB,
    RST_ON_Z        => RST_ON_Z,
    out_o           => posn_incr
);

--
-- SSI Master Instantiation :
--
ssimstr_inst : entity work.ssimstr
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => BITS,
    CLKRATE         => CLKRATE,
    FRAMERATE       => FRAMERATE,
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
