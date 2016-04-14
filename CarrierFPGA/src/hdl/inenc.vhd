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
use work.top_defines.all;

entity inenc is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Encoder I/O Pads
    a_i                 : in  std_logic;
    b_i                 : in  std_logic;
    z_i                 : in  std_logic;
    clk_out_o           : out std_logic;
    data_in_i           : in  std_logic;
    clk_in_i            : in  std_logic;
    conn_o              : out std_logic;
    -- Block Parameters
    DCARD_MODE          : in  std_logic_vector(31 downto 0);
    PROTOCOL            : in  std_logic_vector(2 downto 0);
    CLK_PERIOD          : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD        : in  std_logic_vector(31 downto 0);
    BITS                : in  std_logic_vector(7 downto 0);
    BITS_CRC            : in  std_logic_vector(7 downto 0);
    SETP                : in  std_logic_vector(31 downto 0);
    SETP_WSTB           : in  std_logic;
    RST_ON_Z            : in  std_logic;
    -- Block Outputs
    posn_o              : out std_logic_vector(31 downto 0);
    posn_upper_o        : out std_logic_vector(31 downto 0)
);
end entity;

architecture rtl of inenc is

signal posn_incr            : std_logic_vector(31 downto 0);
signal posn_ssi             : std_logic_vector(31 downto 0);
signal posn_ssi_sniffer     : std_logic_vector(31 downto 0);
signal posn_biss_sniffer    : std_logic_vector(47 downto 0);

begin

-- Unused outputs
posn_upper_o <= (others => '0');

-- Connection status comes from Slow FPGA interface on CTRL_D12
conn_o <= DCARD_MODE(0);

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
ssi_master_inst : entity work.ssi_master
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => BITS,
    CLK_PERIOD      => CLK_PERIOD,
    FRAME_PERIOD    => FRAME_PERIOD,
    ssi_sck_o       => clk_out_o,
    ssi_dat_i       => data_in_i,
    posn_o          => posn_ssi,
    posn_valid_o    => open
);

--
-- SSI Sniffer Instantiation :
--
ssi_sniffer_inst : entity work.ssi_sniffer
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => BITS,
    ssi_sck_i       => clk_in_i,
    ssi_dat_i       => data_in_i,
    posn_o          => posn_ssi_sniffer
);

--
-- BISS Sniffer Instantiation :
--
biss_sniffer_inst : entity work.biss_sniffer
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => BITS,
    BITS_CRC        => BITS_CRC,
    ssi_sck_i       => clk_in_i,
    ssi_dat_i       => data_in_i,
    posn_o          => posn_biss_sniffer
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
            when "001"  =>              -- SSI & Loopback
                if (DCARD_MODE(3 downto 1) = DCARD_LOOPBACK) then
                    posn_o <= posn_ssi_sniffer;
                else
                    posn_o <= posn_ssi;
                end if;
            when "010"  =>              -- BISS & Loopback
                if (DCARD_MODE(3 downto 1) = DCARD_LOOPBACK) then
                    posn_o <= posn_biss_sniffer(31 downto 0);
                else
                    posn_o <= (others => '0');
                end if;
            when others =>
                posn_o <= (others => '0');
        end case;
    end if;
end process;

end rtl;
