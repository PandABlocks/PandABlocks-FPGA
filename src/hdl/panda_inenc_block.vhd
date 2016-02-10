--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Control register interface for INENC block.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.type_defines.all;
use work.addr_defines.all;

entity panda_inenc_block is
port (
    -- Clock and Reset.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface.
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    -- Encoder I/O Pads.
    a_i                 : in  std_logic;
    b_i                 : in  std_logic;
    z_i                 : in  std_logic;
    mclk_o              : out std_logic;
    mdat_i              : in  std_logic;
    mdat_o              : out std_logic;
    conn_i              : in  std_logic;
    -- Loopback outputs.
    a_o                 : out std_logic;
    b_o                 : out std_logic;
    z_o                 : out std_logic;
    conn_o              : out std_logic;
    -- Block Outputs.
    slow_tlp_o          : out slow_packet;
    posn_o              : out std_logic_vector(31 downto 0);
    iobuf_ctrl_o        : out std_logic_vector(2 downto 0)
);
end entity;

architecture rtl of panda_inenc_block is

-- Block Configuration Registers
signal PROTOCOL         : std_logic_vector(2 downto 0);
signal CLKRATE          : std_logic_vector(31 downto 0);
signal FRAMERATE        : std_logic_vector(31 downto 0);
signal BITS             : std_logic_vector(7 downto 0);
signal SETP             : std_logic_vector(31 downto 0);
signal SETP_WSTB        : std_logic;
signal RST_ON_Z         : std_logic;

signal reset            : std_logic;
signal slow             : slow_packet;

signal mem_addr         : natural range 0 to (2**mem_addr_i'length - 1);

begin

-- Integer conversion for address.
mem_addr <= to_integer(unsigned(mem_addr_i));

-- A write to a configuration register initiates a reset on the core
-- block.
reset <= reset_i or (mem_cs_i and mem_wstb_i);

--
-- Configuration Register Read
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            PROTOCOL  <= "000";
            CLKRATE   <= (others => '0');
            FRAMERATE <= (others => '0');
            BITS      <= (others => '0');
            SETP      <= (others => '0');
            SETP_WSTB <= '0';
            RST_ON_Z  <= '0';
        else
            -- Setpoint write strobe
            SETP_WSTB <= '0';

             if (mem_cs_i = '1' and mem_wstb_i = '1') then
                if (mem_addr = INENC_PROTOCOL) then
                    PROTOCOL <= mem_dat_i(2 downto 0);
                end if;

                if (mem_addr = INENC_CLKRATE) then
                    CLKRATE <= mem_dat_i;
                end if;

                if (mem_addr = INENC_FRAMERATE) then
                    FRAMERATE <= mem_dat_i;
                end if;

                if (mem_addr = INENC_BITS) then
                    BITS <= mem_dat_i(7 downto 0);
                end if;

                if (mem_addr = INENC_SETP) then
                    SETP <= mem_dat_i(31 downto 0);
                    SETP_WSTB <= '1';
                end if;

                if (mem_addr = INENC_RST_ON_Z) then
                    RST_ON_Z <= mem_dat_i(0);
                end if;
           end if;
        end if;
    end if;
end process;

panda_inenc_inst : entity work.panda_inenc
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset,
    -- Encoder I/O Pads
    a_i                 => a_i,
    b_i                 => b_i,
    z_i                 => z_i,
    mclk_o              => mclk_o,
    mdat_i              => mdat_i,
    mdat_o              => mdat_o,
    conn_i              => conn_i,
    -- Loopback outputs.
    a_o                 => a_o,
    b_o                 => b_o,
    z_o                 => z_o,
    conn_o              => conn_o,
    -- Block Parameters
    PROTOCOL            => PROTOCOL,
    CLKRATE             => CLKRATE,
    FRAMERATE           => FRAMERATE,
    BITS                => BITS,
    SETP                => SETP,
    SETP_WSTB           => SETP_WSTB,
    RST_ON_Z            => RST_ON_Z,
    -- Status
    posn_o              => posn_o,
    iobuf_ctrl_o        => iobuf_ctrl_o
);

--
-- Issue a Write command to Slow Controller when a write is detected on
-- PROTOCOL register
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
                if (mem_addr = INENC_PROTOCOL) then
                    slow.strobe <= '1';
                    slow.address <= ZEROS(PAGE_AW-BLK_AW) & mem_addr_i;
                    case (mem_dat_i(2 downto 0)) is
                        when "000"  => -- INC
                            slow.data <= ZEROS(24) & X"03";
                        when "001"  => -- SSI
                            slow.data <= ZEROS(24) & X"0C";
                        when "010"  => -- EnDat
                            slow.data <= ZEROS(24) & X"14";
                        when "011"  => -- BiSS
                            slow.data <= ZEROS(24) & X"1C";
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
