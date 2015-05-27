library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Block : IN TTL
--
entity inttl is
port (
    clk_i       : in  std_logic;
    pad_i       : in  std_logic;
    val_o       : out std_logic
);
end inttl;

architecture rtl of inttl is

begin

process(clk_i)
begin
    if rising_edge(clk_i) then
        val_o <= pad_i;
    end if;
end process;

end rtl;

-- Block : OUT TTL
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity outttl is
port (
    clk_i       : in  std_logic;
    val_i       : in  std_logic;
    pad_o       : out std_logic
);
end outttl;

architecture rtl of outttl is

begin

process(clk_i)
begin
    if rising_edge(clk_i) then
        pad_o <= val_i;
    end if;
end process;

end rtl;

-- Block : IN LVDS
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity inlvds is
port (
    clk_i       : in  std_logic;
    pad_i       : in  std_logic;
    val_o       : out std_logic
);
end inlvds;

architecture rtl of inlvds is

begin

process(clk_i)
begin
    if rising_edge(clk_i) then
        val_o <= pad_i;
    end if;
end process;

end rtl;

-- Block : OUT LVDS
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity outlvds is
port (
    clk_i       : in  std_logic;
    val_i       : in  std_logic;
    pad_o       : out std_logic
);
end outlvds;

architecture rtl of outlvds is

begin

process(clk_i)
begin
    if rising_edge(clk_i) then
        pad_o <= val_i;
    end if;
end process;

end rtl;

--
-- Top-level Digital IO
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.register_map.all;

entity panda_digitalio is
generic (
    TTLN                : natural := 8;
    LVDSN               : natural := 2
);
port (
    -- Clocks and Resets
    sysclk_i            : in  std_logic;
    sysreset_i          : in  std_logic;

    -- TTL
    ttl_pad_i           : in  std_logic_vector(TTLN-1 downto 0);
    inttl_o             : out std_logic_vector(TTLN-1 downto 0);
    ttl_pad_o           : out std_logic_vector(TTLN-1 downto 0);

    -- LVDS
    lvds_pad_i          : in  std_logic_vector(LVDSN-1 downto 0);
    inlvds_o            : out std_logic_vector(LVDSN-1 downto 0);
    lvds_pad_o          : out std_logic_vector(LVDSN-1 downto 0);

    -- System Bus
    system_bus_i        : in  std_logic_vector(SBUSW-1 downto 0);

    -- System Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_addr_i          : in  std_logic_vector(9 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    mem_wstb_i          : in  std_logic;
    mem_rstb_i          : in  std_logic
);
end panda_digitalio;

architecture rtl of panda_digitalio is

signal outttl_val   : sbus_muxsel_array(TTLN-1 downto 0);
signal outlvds_val  : sbus_muxsel_array(LVDSN-1 downto 0);

begin

-- Module CSR interface:
-- Multiplexer Select values for TTL/LVDS output blocks.
process(sysclk_i)
begin
    if rising_edge(sysclk_i) then
        if (mem_cs_i = '1' and mem_wstb_i = '1') then
            if (mem_addr_i = OUTTTL0_VAL) then
                outttl_val(0) <= mem_dat_i(SBUSBW-1 downto 0);
            end if;
            if (mem_addr_i = OUTTTL1_VAL) then
                outttl_val(1) <= mem_dat_i(SBUSBW-1 downto 0);
            end if;
            if (mem_addr_i = OUTTTL2_VAL) then
                outttl_val(2) <= mem_dat_i(SBUSBW-1 downto 0);
            end if;
            if (mem_addr_i = OUTTTL3_VAL) then
                outttl_val(3) <= mem_dat_i(SBUSBW-1 downto 0);
            end if;
            if (mem_addr_i = OUTTTL4_VAL) then
                outttl_val(4) <= mem_dat_i(SBUSBW-1 downto 0);
            end if;
            if (mem_addr_i = OUTTTL5_VAL) then
                outttl_val(5) <= mem_dat_i(SBUSBW-1 downto 0);
            end if;
            if (mem_addr_i = OUTTTL6_VAL) then
                outttl_val(6) <= mem_dat_i(SBUSBW-1 downto 0);
            end if;
            if (mem_addr_i = OUTTTL7_VAL) then
                outttl_val(7) <= mem_dat_i(SBUSBW-1 downto 0);
            end if;
            if (mem_addr_i = OUTLVDS0_VAL) then
                outlvds_val(0) <= mem_dat_i(SBUSBW-1 downto 0);
            end if;
            if (mem_addr_i = OUTLVDS1_VAL) then
                outlvds_val(1) <= mem_dat_i(SBUSBW-1 downto 0);
            end if;
        end if;
    end if;
end process;

-- Instantiate all TTL and LVDS input and output blocks as required
inttl_gen : for N in 0 to TTLN-1 generate
inttl_inst : entity work.inttl
port map (clk_i => sysclk_i, pad_i => ttl_pad_i(N), val_o => inttl_o(N));
end generate;

outttl_gen : for N in 0 to TTLN-1 generate
outttl_inst : entity work.outttl
port map (clk_i => sysclk_i, val_i => SBIT(system_bus_i, outttl_val(N)), pad_o => ttl_pad_o(N));
end generate;

inlvds_gen : for N in 0 to LVDSN-1 generate
inlvds_inst : entity work.inlvds
port map (clk_i => sysclk_i, pad_i => lvds_pad_i(N), val_o => inlvds_o(N));
end generate;

outlvds_gen : for N in 0 to LVDSN-1 generate
outlvds_inst : entity work.outlvds
port map (clk_i => sysclk_i, val_i => SBIT(system_bus_i, outlvds_val(N)), pad_o => lvds_pad_o(N));
end generate;


end rtl;


