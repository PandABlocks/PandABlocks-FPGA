library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_reg is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_rstb_i          : in  std_logic;
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Encoder I/O Pads
    sysbus_i            : in  sysbus_t
);
end panda_reg;

architecture rtl of panda_reg is

type bit16_array_t is array(natural range <>) of std_logic_vector(15 downto 0);

signal sysbus               : bit16_array_t(7 downto 0) :=
                                    (others => (others => '0'));
signal sysbus_prev          : bit16_array_t(7 downto 0) :=
                                    (others => (others => '0'));
signal sysbus_change        : bit16_array_t(7 downto 0) :=
                                    (others => (others => '0'));

signal sysbus_change_clear  : std_logic_vector(7 downto 0) :=
                                    (others => '0');

signal index                : unsigned(2 downto 0):= "000";
signal index_prev           : unsigned(2 downto 0):= "000";
signal sysbus_rstb          : std_logic := '0';

begin

--
-- System Bus is un-packed into an array of 16-bit words, so that on a
-- single 32-bit Read Strobe, following fields can be read simultaneously.
-- mem_dat_o[31:16] = N*SysBus[15:0]
-- mem_dat_o[15: 0] = N*Changed[15:0]
process(sysbus_i)
begin
    for I in 0 to 7 loop
        sysbus(I) <= sysbus_i(I*16+15 downto I*16);
    end loop;
end process;

-- Keep track of incoming BIT_READ_* write and read strobes to generate
-- change clear flag, index for the current 16-bit word and data out
-- strobe.
process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Clear and Read Strobe is a single clock flag
        sysbus_change_clear <= (others => '0');
        sysbus_rstb <= '0';

        if (mem_cs_i = '1' and mem_wstb_i = '1' and
              mem_addr_i(BLK_AW-1 downto 0) = REG_BIT_READ_RST) then
            index <= (others => '0');
        elsif (mem_cs_i = '1' and mem_rstb_i = '1' and
              mem_addr_i(BLK_AW-1 downto 0) = REG_BIT_READ_VALUE) then
            index <= index + 1;
            sysbus_change_clear(to_integer(index)) <= '1';
            sysbus_rstb <= '1';
        end if;

        -- The mem_dat_o read is delayed to prevent race condition since
        -- change clear flag and index follows one clock after mem_rstb_i.
        index_prev <= index;

        -- Latch sysbus_prev since current sysbus value has an impact on the
        -- next clock cycle.
        if (sysbus_rstb = '1') then
            mem_dat_o <= sysbus_prev(to_integer(index_prev))
                            & sysbus_change(to_integer(index_prev));
        end if;
    end if;
end process;

--
-- Change register is cleared on read, and it keeps track of changes on the
-- system bus.
process(clk_i)
begin
    if rising_edge(clk_i) then
        sysbus_prev <= sysbus;
        for I in 0 to 7 loop
            -- Reset/Clear to current change status rather than 0.
            if (sysbus_change_clear(I) = '1') then
                sysbus_change(I) <= sysbus(I) xor sysbus_prev(I);
            else
                sysbus_change(I) <= (sysbus(I) xor sysbus_prev(I)) or sysbus_change(I);
            end if;
        end loop;
    end if;
end process;

end rtl;

