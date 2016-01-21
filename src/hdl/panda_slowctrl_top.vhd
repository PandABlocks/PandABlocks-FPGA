--------------------------------------------------------------------------------
--  File:       panda_slowctrl_top.vhd
--  Desc:       Position capture module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_slowctrl_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Output pulses
    enc0_ctrl_o         : out std_logic_vector(11 downto 0)
);
end panda_slowctrl_top;

architecture rtl of panda_slowctrl_top is

signal inenc_buf_ctrl       : std_logic_vector(5 downto 0);
signal outenc_buf_ctrl      : std_logic_vector(5 downto 0);

begin

mem_dat_o <= (others => '0');

--
-- Control System Register Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            inenc_buf_ctrl  <= "000011";
            outenc_buf_ctrl <= "000111";
        else

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- DCard Input Channel Buffer Ctrl
                -- Inc   : 0x03
                -- SSI   : 0x0C
                -- Endat : 0x14
                -- BiSS  : 0x1C
                if (mem_addr_i = SLOW_INENC_CTRL_ADDR) then
                    inenc_buf_ctrl <= mem_dat_i(5 downto 0);
                end if;

                -- DCard Output Channel Buffer Ctrl
                -- Inc   : 0x07
                -- SSI   : 0x28
                -- Endat : 0x10
                -- BiSS  : 0x18
                -- Pass  : 0x07
                -- DCard Output Channel Buffer Ctrl
                if (mem_addr_i = SLOW_OUTENC_CTRL_ADDR) then
                    outenc_buf_ctrl <= mem_dat_i(5 downto 0);
                end if;
           end if;
        end if;
    end if;
end process;

--
-- Status Register Read
--
REG_READ : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            mem_dat_o <= (others => '0');
        else
            case (mem_addr_i) is
                when SLOW_VERSION_ADDR =>
                    mem_dat_o <= X"87654321";
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

-- Daughter Card Buffer Control Signals
enc0_ctrl_o(1 downto 0) <= inenc_buf_ctrl(1 downto 0);
enc0_ctrl_o(3 downto 2) <= outenc_buf_ctrl(1 downto 0);
enc0_ctrl_o(4) <= inenc_buf_ctrl(2);
enc0_ctrl_o(5) <= outenc_buf_ctrl(2);
enc0_ctrl_o(7 downto 6) <= inenc_buf_ctrl(4 downto 3);
enc0_ctrl_o(9 downto 8) <= outenc_buf_ctrl(4 downto 3);
enc0_ctrl_o(10) <= inenc_buf_ctrl(5);
enc0_ctrl_o(11) <= outenc_buf_ctrl(5);

end rtl;

