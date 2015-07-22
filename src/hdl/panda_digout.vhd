--------------------------------------------------------------------------------
--  File:       panda_digout.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_digout is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    -- Output pulse
    pulse_o             : out std_logic
);
end panda_digout;

architecture rtl of panda_digout is

signal DIGOUT_VAL       : std_logic_vector(SBUSBW-1 downto 0);

begin

-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (mem_cs_i = '1' and mem_wstb_i = '1') then
            -- Pulse start position
            if (mem_addr_i = DIGOUT_VAL_ADDR) then
                DIGOUT_VAL <= mem_dat_i(SBUSBW-1 downto 0);
            end if;
        end if;
    end if;
end process;

--
-- Design Bus Assignments
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        pulse_o <= SBIT(sysbus_i, DIGOUT_VAL);
    end if;
end process;

end rtl;

